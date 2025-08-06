;; Chemical Storage Facility Inspection Contract
;; Inspects facilities that store large quantities of hazardous chemicals

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-FACILITY-NOT-FOUND (err u201))
(define-constant ERR-INSPECTION-NOT-FOUND (err u202))
(define-constant ERR-INVALID-INPUT (err u203))
(define-constant ERR-INSPECTION-ALREADY-COMPLETED (err u204))

;; Data Variables
(define-data-var facility-counter uint u0)
(define-data-var inspection-counter uint u0)
(define-data-var contract-admin principal CONTRACT-OWNER)

;; Data Maps
(define-map facilities
  { facility-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 150),
    operator: (string-ascii 100),
    chemical-types: (string-ascii 200),
    storage-capacity: uint,
    registration-date: uint,
    status: (string-ascii 20)
  }
)

(define-map inspections
  { inspection-id: uint }
  {
    facility-id: uint,
    inspector: principal,
    scheduled-date: uint,
    actual-date: uint,
    inspection-type: (string-ascii 30),
    status: (string-ascii 20)
  }
)

(define-map inspection-results
  { inspection-id: uint }
  {
    compliance-score: uint,
    violations-found: uint,
    safety-rating: (string-ascii 20),
    corrective-actions: (string-ascii 300),
    next-inspection-due: uint
  }
)

(define-map authorized-inspectors principal bool)

;; Authorization Functions
(define-public (add-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-inspectors inspector true))
  )
)

(define-public (remove-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-inspectors inspector))
  )
)

;; Core Functions
(define-public (register-facility
  (name (string-ascii 100))
  (location (string-ascii 150))
  (operator (string-ascii 100))
  (chemical-types (string-ascii 200))
  (storage-capacity uint))
  (let
    (
      (facility-id (+ (var-get facility-counter) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> (len operator) u0) ERR-INVALID-INPUT)
    (asserts! (> storage-capacity u0) ERR-INVALID-INPUT)

    (map-set facilities
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        operator: operator,
        chemical-types: chemical-types,
        storage-capacity: storage-capacity,
        registration-date: current-time,
        status: "active"
      }
    )

    (var-set facility-counter facility-id)
    (ok facility-id)
  )
)

(define-public (schedule-inspection
  (facility-id uint)
  (inspector principal)
  (scheduled-date uint))
  (let
    (
      (inspection-id (+ (var-get inspection-counter) u1))
      (facility-data (unwrap! (map-get? facilities { facility-id: facility-id }) ERR-FACILITY-NOT-FOUND))
    )
    (asserts! (default-to false (map-get? authorized-inspectors tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status facility-data) "active") ERR-FACILITY-NOT-FOUND)
    (asserts! (> scheduled-date u0) ERR-INVALID-INPUT)

    (map-set inspections
      { inspection-id: inspection-id }
      {
        facility-id: facility-id,
        inspector: inspector,
        scheduled-date: scheduled-date,
        actual-date: u0,
        inspection-type: "routine",
        status: "scheduled"
      }
    )

    (var-set inspection-counter inspection-id)
    (ok inspection-id)
  )
)

(define-public (conduct-inspection
  (inspection-id uint)
  (compliance-score uint)
  (violations-found uint)
  (safety-rating (string-ascii 20))
  (corrective-actions (string-ascii 300)))
  (let
    (
      (inspection-data (unwrap! (map-get? inspections { inspection-id: inspection-id }) ERR-INSPECTION-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (next-inspection (+ current-time u7776000)) ;; 90 days
    )
    (asserts! (is-eq tx-sender (get inspector inspection-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status inspection-data) "scheduled") ERR-INSPECTION-ALREADY-COMPLETED)
    (asserts! (<= compliance-score u100) ERR-INVALID-INPUT)
    (asserts! (> (len safety-rating) u0) ERR-INVALID-INPUT)

    (map-set inspections
      { inspection-id: inspection-id }
      (merge inspection-data {
        actual-date: current-time,
        status: "completed"
      })
    )

    (map-set inspection-results
      { inspection-id: inspection-id }
      {
        compliance-score: compliance-score,
        violations-found: violations-found,
        safety-rating: safety-rating,
        corrective-actions: corrective-actions,
        next-inspection-due: next-inspection
      }
    )

    (ok true)
  )
)

(define-public (schedule-emergency-inspection
  (facility-id uint)
  (inspector principal)
  (reason (string-ascii 200)))
  (let
    (
      (inspection-id (+ (var-get inspection-counter) u1))
      (facility-data (unwrap! (map-get? facilities { facility-id: facility-id }) ERR-FACILITY-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (default-to false (map-get? authorized-inspectors tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status facility-data) "active") ERR-FACILITY-NOT-FOUND)
    (asserts! (> (len reason) u0) ERR-INVALID-INPUT)

    (map-set inspections
      { inspection-id: inspection-id }
      {
        facility-id: facility-id,
        inspector: inspector,
        scheduled-date: current-time,
        actual-date: u0,
        inspection-type: "emergency",
        status: "scheduled"
      }
    )

    (var-set inspection-counter inspection-id)
    (ok inspection-id)
  )
)

;; Read-only Functions
(define-read-only (get-facility (facility-id uint))
  (map-get? facilities { facility-id: facility-id })
)

(define-read-only (get-inspection (inspection-id uint))
  (map-get? inspections { inspection-id: inspection-id })
)

(define-read-only (get-inspection-results (inspection-id uint))
  (map-get? inspection-results { inspection-id: inspection-id })
)

(define-read-only (get-facility-count)
  (var-get facility-counter)
)

(define-read-only (get-inspection-count)
  (var-get inspection-counter)
)

(define-read-only (is-authorized-inspector (inspector principal))
  (default-to false (map-get? authorized-inspectors inspector))
)
