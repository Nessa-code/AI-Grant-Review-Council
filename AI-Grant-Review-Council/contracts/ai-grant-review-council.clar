;; ai-grant-council.clar
;; AI-powered grant review and allocation system for educational initiatives

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-submitted (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-insufficient-funds (err u104))

;; Data variables
(define-data-var proposal-counter uint u0)
(define-data-var review-counter uint u0)
(define-data-var grant-pool uint u0)

;; Data maps
(define-map proposals
    { proposal-id: uint }
    {
        applicant: principal,
        title: (string-ascii 100),
        category: (string-ascii 50),
        amount-requested: uint,
        status: (string-ascii 20),
        ai-score: uint,
        reviewer-count: uint,
        total-score: uint,
        submitted-at: uint
    }
)

(define-map reviews
    { review-id: uint }
    {
        proposal-id: uint,
        reviewer: principal,
        score: uint,
        timestamp: uint
    }
)

(define-map reviewer-status
    { reviewer: principal, proposal-id: uint }
    { reviewed: bool }
)

(define-map council-members
    { member: principal }
    { active: bool, reviews-completed: uint }
)

(define-map grant-awards
    { proposal-id: uint }
    { awarded: bool, amount: uint, disbursed: bool }
)

;; Add council member
(define-public (add-council-member (member principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set council-members
            { member: member }
            { active: true, reviews-completed: u0 }
        )
        (ok true)
    )
)

;; Submit grant proposal
(define-public (submit-proposal (title (string-ascii 100)) (category (string-ascii 50)) (amount-requested uint))
    (let
        (
            (new-id (+ (var-get proposal-counter) u1))
            (existing (map-get? proposals { proposal-id: new-id }))
        )
        (asserts! (is-none existing) err-already-submitted)
        (map-set proposals
            { proposal-id: new-id }
            {
                applicant: tx-sender,
                title: title,
                category: category,
                amount-requested: amount-requested,
                status: "pending",
                ai-score: u0,
                reviewer-count: u0,
                total-score: u0,
                submitted-at: stacks-block-height
            }
        )
        (var-set proposal-counter new-id)
        (ok new-id)
    )
)

;; Submit AI assessment score
(define-public (set-ai-score (proposal-id uint) (score uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= score u100) (err u105))
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { ai-score: score })
        )
        (ok true)
    )
)

;; Submit review
(define-public (submit-review (proposal-id uint) (score uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
            (member (unwrap! (map-get? council-members { member: tx-sender }) err-owner-only))
            (new-review-id (+ (var-get review-counter) u1))
        )
        (asserts! (get active member) err-owner-only)
        (asserts! (is-none (map-get? reviewer-status { reviewer: tx-sender, proposal-id: proposal-id })) err-already-submitted)
        (asserts! (<= score u100) (err u105))
        (map-set reviews
            { review-id: new-review-id }
            {
                proposal-id: proposal-id,
                reviewer: tx-sender,
                score: score,
                timestamp: stacks-block-height
            }
        )
        (map-set reviewer-status
            { reviewer: tx-sender, proposal-id: proposal-id }
            { reviewed: true }
        )
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal {
                reviewer-count: (+ (get reviewer-count proposal) u1),
                total-score: (+ (get total-score proposal) score)
            })
        )
        (map-set council-members
            { member: tx-sender }
            (merge member { reviews-completed: (+ (get reviews-completed member) u1) })
        )
        (var-set review-counter new-review-id)
        (ok new-review-id)
    )
)

;; Deactivate council member
(define-public (deactivate-council-member (member principal))
    (let
        (
            (member-data (unwrap! (map-get? council-members { member: member }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set council-members
            { member: member }
            (merge member-data { active: false })
        )
        (ok true)
    )
)

;; Reactivate council member
(define-public (reactivate-council-member (member principal))
    (let
        (
            (member-data (unwrap! (map-get? council-members { member: member }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set council-members
            { member: member }
            (merge member-data { active: true })
        )
        (ok true)
    )
)

;; Update proposal status
(define-public (update-proposal-status (proposal-id uint) (new-status (string-ascii 20)))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: new-status })
        )
        (ok true)
    )
)

;; Add funds to grant pool
(define-public (add-to-grant-pool (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set grant-pool (+ (var-get grant-pool) amount))
        (ok (var-get grant-pool))
    )
)

;; Withdraw from grant pool (owner only)
(define-public (withdraw-from-pool (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= amount (var-get grant-pool)) err-insufficient-funds)
        (var-set grant-pool (- (var-get grant-pool) amount))
        (ok (var-get grant-pool))
    )
)

;; Reject proposal
(define-public (reject-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "rejected" })
        )
        (ok true)
    )
)

;; Approve proposal for review
(define-public (approve-for-review (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "under-review" })
        )
        (ok true)
    )
)

;; Close proposal
(define-public (close-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "closed" })
        )
        (ok true)
    )
)

;; Update proposal amount
(define-public (update-proposal-amount (proposal-id uint) (new-amount uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get applicant proposal)) err-owner-only)
        (asserts! (is-eq (get status proposal) "pending") err-invalid-status)
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { amount-requested: new-amount })
        )
        (ok true)
    )
)

;; Award grant
(define-public (award-grant (proposal-id uint) (amount uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= amount (var-get grant-pool)) err-insufficient-funds)
        (map-set grant-awards
            { proposal-id: proposal-id }
            { awarded: true, amount: amount, disbursed: false }
        )
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "awarded" })
        )
        (var-set grant-pool (- (var-get grant-pool) amount))
        (ok true)
    )
)

;; Disburse awarded grant
(define-public (disburse-grant (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
            (award (unwrap! (map-get? grant-awards { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get awarded award) err-invalid-status)
        (asserts! (not (get disbursed award)) err-already-submitted)
        (map-set grant-awards
            { proposal-id: proposal-id }
            (merge award { disbursed: true })
        )
        (ok true)
    )
)

;; Cancel grant award
(define-public (cancel-award (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
            (award (unwrap! (map-get? grant-awards { proposal-id: proposal-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (get disbursed award)) err-invalid-status)
        (var-set grant-pool (+ (var-get grant-pool) (get amount award)))
        (map-set grant-awards
            { proposal-id: proposal-id }
            { awarded: false, amount: u0, disbursed: false }
        )
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "cancelled" })
        )
        (ok true)
    )
)