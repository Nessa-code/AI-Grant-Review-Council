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