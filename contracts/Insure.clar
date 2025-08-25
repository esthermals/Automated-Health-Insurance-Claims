;; title: Insure
;; version: 1.0.0
;; summary: Automated Health Insurance Claims Processing
;; description: A smart contract system that automatically processes and pays out health insurance claims upon verifiable diagnosis.

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-policy-not-found (err u101))
(define-constant err-insufficient-premium (err u102))
(define-constant err-policy-expired (err u103))
(define-constant err-claim-already-processed (err u104))
(define-constant err-invalid-diagnosis (err u105))
(define-constant err-insufficient-funds (err u106))
(define-constant err-claim-not-found (err u107))
(define-constant err-not-authorized (err u108))
(define-constant err-policy-suspended (err u109))
(define-constant err-diagnosis-expired (err u110))

(define-data-var policy-counter uint u0)
(define-data-var claim-counter uint u0)
(define-data-var total-premium-pool uint u0)
(define-data-var total-claims-paid uint u0)

(define-map policies
    { policy-id: uint }
    {
        holder: principal,
        premium-amount: uint,
        coverage-limit: uint,
        start-block: uint,
        end-block: uint,
        active: bool,
        claims-made: uint
    }
)

(define-map claims
    { claim-id: uint }
    {
        policy-id: uint,
        claimant: principal,
        diagnosis-code: (string-ascii 20),
        amount: uint,
        submitted-block: uint,
        processed: bool,
        approved: bool,
        paid-block: (optional uint)
    }
)

(define-map authorized-doctors
    { doctor: principal }
    { verified: bool, specialization: (string-ascii 50) }
)

(define-map diagnoses
    { diagnosis-id: uint }
    {
        patient: principal,
        doctor: principal,
        diagnosis-code: (string-ascii 20),
        confirmed-block: uint,
        valid-until: uint
    }
)

(define-data-var diagnosis-counter uint u0)

(define-public (authorize-doctor (doctor principal) (specialization (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set authorized-doctors { doctor: doctor } { verified: true, specialization: specialization }))
    )
)

(define-public (revoke-doctor (doctor principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-delete authorized-doctors { doctor: doctor }))
    )
)

(define-public (create-policy (coverage-limit uint) (duration-blocks uint))
    (let (
        (policy-id (+ (var-get policy-counter) u1))
        (premium-cost (/ coverage-limit u100))
        (start-block stacks-block-height)
        (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (>= (stx-get-balance tx-sender) premium-cost) err-insufficient-premium)
    (try! (stx-transfer? premium-cost tx-sender (as-contract tx-sender)))
    (map-set policies
        { policy-id: policy-id }
        {
            holder: tx-sender,
            premium-amount: premium-cost,
            coverage-limit: coverage-limit,
            start-block: start-block,
            end-block: end-block,
            active: true,
            claims-made: u0
        }
    )
    (var-set policy-counter policy-id)
    (var-set total-premium-pool (+ (var-get total-premium-pool) premium-cost))
    (ok policy-id)
    )
)

(define-public (submit-diagnosis (patient principal) (diagnosis-code (string-ascii 20)) (validity-blocks uint))
    (let (
        (diagnosis-id (+ (var-get diagnosis-counter) u1))
        (doctor-auth (map-get? authorized-doctors { doctor: tx-sender }))
    )
    (asserts! (is-some doctor-auth) err-not-authorized)
    (map-set diagnoses
        { diagnosis-id: diagnosis-id }
        {
            patient: patient,
            doctor: tx-sender,
            diagnosis-code: diagnosis-code,
            confirmed-block: stacks-block-height,
            valid-until: (+ stacks-block-height validity-blocks)
        }
    )
    (var-set diagnosis-counter diagnosis-id)
    (ok diagnosis-id)
    )
)

(define-public (submit-claim (policy-id uint) (diagnosis-code (string-ascii 20)) (amount uint))
    (let (
        (policy (unwrap! (map-get? policies { policy-id: policy-id }) err-policy-not-found))
        (claim-id (+ (var-get claim-counter) u1))
    )
    (asserts! (is-eq (get holder policy) tx-sender) err-not-authorized)
    (asserts! (get active policy) err-policy-suspended)
    (asserts! (<= stacks-block-height (get end-block policy)) err-policy-expired)
    (asserts! (<= amount (get coverage-limit policy)) err-insufficient-funds)
    (map-set claims
        { claim-id: claim-id }
        {
            policy-id: policy-id,
            claimant: tx-sender,
            diagnosis-code: diagnosis-code,
            amount: amount,
            submitted-block: stacks-block-height,
            processed: false,
            approved: false,
            paid-block: none
        }
    )
    (var-set claim-counter claim-id)
    (ok claim-id)
    )
)

(define-public (process-claim (claim-id uint) (diagnosis-id uint))
    (let (
        (claim (unwrap! (map-get? claims { claim-id: claim-id }) err-claim-not-found))
        (policy (unwrap! (map-get? policies { policy-id: (get policy-id claim) }) err-policy-not-found))
        (diagnosis (unwrap! (map-get? diagnoses { diagnosis-id: diagnosis-id }) err-invalid-diagnosis))
    )
    (asserts! (not (get processed claim)) err-claim-already-processed)
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) (get amount claim)) err-insufficient-funds)
    (asserts! (is-eq (get patient diagnosis) (get claimant claim)) err-not-authorized)
    (asserts! (is-eq (get diagnosis-code diagnosis) (get diagnosis-code claim)) err-invalid-diagnosis)
    (asserts! (<= stacks-block-height (get valid-until diagnosis)) err-diagnosis-expired)
    
    (try! (as-contract (stx-transfer? (get amount claim) tx-sender (get claimant claim))))
    (map-set claims
        { claim-id: claim-id }
        (merge claim { processed: true, approved: true, paid-block: (some stacks-block-height) })
    )
    (map-set policies
        { policy-id: (get policy-id claim) }
        (merge policy { claims-made: (+ (get claims-made policy) u1) })
    )
    (var-set total-claims-paid (+ (var-get total-claims-paid) (get amount claim)))
    (ok true)
    )
)

(define-public (suspend-policy (policy-id uint))
    (let (
        (policy (unwrap! (map-get? policies { policy-id: policy-id }) err-policy-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set policies
        { policy-id: policy-id }
        (merge policy { active: false })
    )
    (ok true)
    )
)

(define-public (reactivate-policy (policy-id uint))
    (let (
        (policy (unwrap! (map-get? policies { policy-id: policy-id }) err-policy-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set policies
        { policy-id: policy-id }
        (merge policy { active: true })
    )
    (ok true)
    )
)

(define-public (extend-policy (policy-id uint) (additional-blocks uint))
    (let (
        (policy (unwrap! (map-get? policies { policy-id: policy-id }) err-policy-not-found))
        (extension-cost (/ (get coverage-limit policy) u200))
    )
    (asserts! (is-eq (get holder policy) tx-sender) err-not-authorized)
    (asserts! (>= (stx-get-balance tx-sender) extension-cost) err-insufficient-premium)
    (try! (stx-transfer? extension-cost tx-sender (as-contract tx-sender)))
    (map-set policies
        { policy-id: policy-id }
        (merge policy { end-block: (+ (get end-block policy) additional-blocks) })
    )
    (var-set total-premium-pool (+ (var-get total-premium-pool) extension-cost))
    (ok true)
    )
)

(define-read-only (get-policy (policy-id uint))
    (map-get? policies { policy-id: policy-id })
)

(define-read-only (get-claim (claim-id uint))
    (map-get? claims { claim-id: claim-id })
)

(define-read-only (get-diagnosis (diagnosis-id uint))
    (map-get? diagnoses { diagnosis-id: diagnosis-id })
)

(define-read-only (is-doctor-authorized (doctor principal))
    (is-some (map-get? authorized-doctors { doctor: doctor }))
)

(define-read-only (get-doctor-info (doctor principal))
    (map-get? authorized-doctors { doctor: doctor })
)

(define-read-only (get-policy-status (policy-id uint))
    (match (map-get? policies { policy-id: policy-id })
        policy (ok {
            active: (get active policy),
            expired: (> stacks-block-height (get end-block policy)),
            claims-remaining: (- (get coverage-limit policy) (* (get claims-made policy) u1000))
        })
        err-policy-not-found
    )
)

(define-read-only (get-contract-stats)
    (ok {
        total-policies: (var-get policy-counter),
        total-claims: (var-get claim-counter),
        total-diagnoses: (var-get diagnosis-counter),
        premium-pool: (var-get total-premium-pool),
        claims-paid: (var-get total-claims-paid)
    })
)

(define-read-only (is-diagnosis-valid (diagnosis-id uint) (patient principal) (diagnosis-code (string-ascii 20)))
    (match (map-get? diagnoses { diagnosis-id: diagnosis-id })
        diagnosis (and 
            (is-eq (get patient diagnosis) patient)
            (is-eq (get diagnosis-code diagnosis) diagnosis-code)
            (<= stacks-block-height (get valid-until diagnosis))
        )
        false
    )
)
