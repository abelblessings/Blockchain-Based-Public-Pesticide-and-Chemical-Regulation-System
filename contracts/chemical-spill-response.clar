;; Chemical Spill Response Coordination Contract
;; Manages cleanup of chemical accidents and spills

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INCIDENT-NOT-FOUND (err u401))
(define-constant ERR-INVALID-INPUT (err u402))
(define-constant ERR-INCIDENT-ALREADY-CLOSED (err u403))
(define-constant ERR-TEAM-NOT-AVAILABLE (err u404))

;; Data Variables
(define-data-var incident-counter uint u0)
(define-data-var team-counter uint u0)
(define-data-var contract-admin principal CONTRACT-OWNER)

;; Data Maps
(define-map spill-incidents
  { incident-id: uint }
  {
    location: (string-ascii 150),
    chemical-type: (string-ascii 50),
    spill-volume: uint,
    severity-level: (string-ascii 20),
    reported-by: principal,
    report-time: uint,
    status: (string-ascii 20)
  }
)

(define-map response-teams
  { team-id: uint }
  {
    team-name: (string-ascii 50),
    team-leader: principal,
    specialization: (string-ascii 100),
    equipment-level: (string-ascii 20),
    availability-status: (string-ascii 20),
    current-incident: uint
  }
)

(define-map incident-response
  { incident-id: uint }
  {
    assigned-team: uint,
    response-start-time: uint,
    estimated-completion: uint,
    actual-completion: uint,
    cleanup-progress: uint,
    resources-used: (string-ascii 200)
  }
)

(define-map cleanup-reports
  { incident-id: uint }
  {
    environmental-impact: (string-ascii 200),
    cleanup-method: (string-ascii 100),
    waste-disposal: (string-ascii 100),
    final-assessment: (string-ascii 200),
    lessons-learned: (string-ascii 200)
  }
)

(define-map authorized-coordinators principal bool)

;; Authorization Functions
(define-public (add-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-coordinators coordinator true))
  )
)

(define-public (remove-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-coordinators coordinator))
  )
)

;; Core Functions
(define-public (register-response-team
  (team-name (string-ascii 50))
  (team-leader principal)
  (specialization (string-ascii 100))
  (equipment-level (string-ascii 20)))
  (let
    (
      (team-id (+ (var-get team-counter) u1))
    )
    (asserts! (default-to false (map-get? authorized-coordinators tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len team-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len specialization) u0) ERR-INVALID-INPUT)
    (asserts! (> (len equipment-level) u0) ERR-INVALID-INPUT)

    (map-set response-teams
      { team-id: team-id }
      {
        team-name: team-name,
        team-leader: team-leader,
        specialization: specialization,
        equipment-level: equipment-level,
        availability-status: "available",
        current-incident: u0
      }
    )

    (var-set team-counter team-id)
    (ok team-id)
  )
)

(define-public (report-spill-incident
  (location (string-ascii 150))
  (chemical-type (string-ascii 50))
  (spill-volume uint)
  (severity-level (string-ascii 20)))
  (let
    (
      (incident-id (+ (var-get incident-counter) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> (len chemical-type) u0) ERR-INVALID-INPUT)
    (asserts! (> spill-volume u0) ERR-INVALID-INPUT)
    (asserts! (> (len severity-level) u0) ERR-INVALID-INPUT)

    (map-set spill-incidents
      { incident-id: incident-id }
      {
        location: location,
        chemical-type: chemical-type,
        spill-volume: spill-volume,
        severity-level: severity-level,
        reported-by: tx-sender,
        report-time: current-time,
        status: "reported"
      }
    )

    (var-set incident-counter incident-id)
    (ok incident-id)
  )
)

(define-public (assign-response-team
  (incident-id uint)
  (team-id uint)
  (estimated-hours uint))
  (let
    (
      (incident-data (unwrap! (map-get? spill-incidents { incident-id: incident-id }) ERR-INCIDENT-NOT-FOUND))
      (team-data (unwrap! (map-get? response-teams { team-id: team-id }) ERR-INCIDENT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (estimated-completion (+ current-time (* estimated-hours u3600)))
    )
    (asserts! (default-to false (map-get? authorized-coordinators tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status incident-data) "reported") ERR-INCIDENT-ALREADY-CLOSED)
    (asserts! (is-eq (get availability-status team-data) "available") ERR-TEAM-NOT-AVAILABLE)
    (asserts! (> estimated-hours u0) ERR-INVALID-INPUT)

    ;; Update incident status
    (map-set spill-incidents
      { incident-id: incident-id }
      (merge incident-data { status: "assigned" })
    )

    ;; Update team availability
    (map-set response-teams
      { team-id: team-id }
      (merge team-data {
        availability-status: "deployed",
        current-incident: incident-id
      })
    )

    ;; Create response record
    (map-set incident-response
      { incident-id: incident-id }
      {
        assigned-team: team-id,
        response-start-time: current-time,
        estimated-completion: estimated-completion,
        actual-completion: u0,
        cleanup-progress: u0,
        resources-used: "Initial deployment"
      }
    )

    (ok true)
  )
)

(define-public (update-cleanup-progress
  (incident-id uint)
  (progress-percentage uint)
  (resources-update (string-ascii 200)))
  (let
    (
      (response-data (unwrap! (map-get? incident-response { incident-id: incident-id }) ERR-INCIDENT-NOT-FOUND))
      (team-data (unwrap! (map-get? response-teams { team-id: (get assigned-team response-data) }) ERR-INCIDENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get team-leader team-data)) ERR-NOT-AUTHORIZED)
    (asserts! (<= progress-percentage u100) ERR-INVALID-INPUT)
    (asserts! (> (len resources-update) u0) ERR-INVALID-INPUT)

    (map-set incident-response
      { incident-id: incident-id }
      (merge response-data {
        cleanup-progress: progress-percentage,
        resources-used: resources-update
      })
    )

    ;; If 100% complete, update incident status
    (if (is-eq progress-percentage u100)
      (let
        (
          (incident-data (unwrap-panic (map-get? spill-incidents { incident-id: incident-id })))
          (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        )
        (map-set spill-incidents
          { incident-id: incident-id }
          (merge incident-data { status: "cleanup-complete" })
        )

        (map-set incident-response
          { incident-id: incident-id }
          (merge response-data { actual-completion: current-time })
        )

        ;; Free up the team
        (map-set response-teams
          { team-id: (get assigned-team response-data) }
          (merge team-data {
            availability-status: "available",
            current-incident: u0
          })
        )
        (ok true)
      )
      (ok true)
    )
  )
)

(define-public (submit-cleanup-report
  (incident-id uint)
  (environmental-impact (string-ascii 200))
  (cleanup-method (string-ascii 100))
  (waste-disposal (string-ascii 100))
  (final-assessment (string-ascii 200))
  (lessons-learned (string-ascii 200)))
  (let
    (
      (incident-data (unwrap! (map-get? spill-incidents { incident-id: incident-id }) ERR-INCIDENT-NOT-FOUND))
      (response-data (unwrap! (map-get? incident-response { incident-id: incident-id }) ERR-INCIDENT-NOT-FOUND))
      (team-data (unwrap! (map-get? response-teams { team-id: (get assigned-team response-data) }) ERR-INCIDENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get team-leader team-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status incident-data) "cleanup-complete") ERR-INVALID-INPUT)
    (asserts! (> (len environmental-impact) u0) ERR-INVALID-INPUT)
    (asserts! (> (len cleanup-method) u0) ERR-INVALID-INPUT)

    (map-set cleanup-reports
      { incident-id: incident-id }
      {
        environmental-impact: environmental-impact,
        cleanup-method: cleanup-method,
        waste-disposal: waste-disposal,
        final-assessment: final-assessment,
        lessons-learned: lessons-learned
      }
    )

    (map-set spill-incidents
      { incident-id: incident-id }
      (merge incident-data { status: "closed" })
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-incident (incident-id uint))
  (map-get? spill-incidents { incident-id: incident-id })
)

(define-read-only (get-response-team (team-id uint))
  (map-get? response-teams { team-id: team-id })
)

(define-read-only (get-incident-response (incident-id uint))
  (map-get? incident-response { incident-id: incident-id })
)

(define-read-only (get-cleanup-report (incident-id uint))
  (map-get? cleanup-reports { incident-id: incident-id })
)

(define-read-only (get-incident-count)
  (var-get incident-counter)
)

(define-read-only (get-team-count)
  (var-get team-counter)
)

(define-read-only (is-authorized-coordinator (coordinator principal))
  (default-to false (map-get? authorized-coordinators coordinator))
)

(define-read-only (get-active-incidents)
  (let
    (
      (total-incidents (var-get incident-counter))
    )
    ;; This would typically iterate through incidents to count active ones
    ;; For simplicity, returning the total count
    total-incidents
  )
)
