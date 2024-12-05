;; Charity Tracker Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-donation (err u101))
(define-constant err-charity-exists (err u102))
(define-constant err-charity-not-found (err u103))

;; Data Variables
(define-map charities
    principal
    {
        name: (string-ascii 50),
        description: (string-ascii 500),
        total-donations: uint,
        active: bool
    }
)

(define-map donations
    { donor: principal, charity: principal }
    { amount: uint, timestamp: uint }
)

;; Public Functions
(define-public (register-charity (charity-address principal) (name (string-ascii 50)) (description (string-ascii 500)))
    (if (is-eq tx-sender contract-owner)
        (if (is-none (map-get? charities charity-address))
            (begin
                (map-set charities charity-address {
                    name: name,
                    description: description,
                    total-donations: u0,
                    active: true
                })
                (ok true)
            )
            err-charity-exists
        )
        err-owner-only
    )
)

(define-public (make-donation (charity-address principal) (amount uint))
    (let (
        (charity (map-get? charities charity-address))
    )
    (if (and (is-some charity) (get active (unwrap-panic charity)))
        (begin
            (map-set donations { donor: tx-sender, charity: charity-address }
                { amount: amount, timestamp: block-height }
            )
            (map-set charities charity-address
                (merge (unwrap-panic charity)
                    { total-donations: (+ (get total-donations (unwrap-panic charity)) amount) }
                )
            )
            (ok true)
        )
        err-charity-not-found
    ))
)

;; Read-only Functions
(define-read-only (get-charity-info (charity-address principal))
    (ok (map-get? charities charity-address))
)

(define-read-only (get-donation-info (donor principal) (charity-address principal))
    (ok (map-get? donations { donor: donor, charity: charity-address }))
)

(define-read-only (get-total-donations (charity-address principal))
    (let ((charity (map-get? charities charity-address)))
        (if (is-some charity)
            (ok (get total-donations (unwrap-panic charity)))
            err-charity-not-found
        )
    )
)
