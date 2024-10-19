;; EcoLoop Smart Contract

;; Define data variables
(define-data-var total-items uint u0)
(define-map items principal (string-ascii 256))
(define-map user-reputation principal uint)

;; Constants
(define-constant MAX_DESCRIPTION_LENGTH u256)
(define-constant MAX_REPUTATION_POINTS u1000000)

;; Add a new item to the platform
(define-public (add-item (item-description (string-ascii 256)))
  (let ((caller tx-sender)
        (description-length (len item-description)))
    (if (<= description-length MAX_DESCRIPTION_LENGTH)
      (begin
        (map-set items caller item-description)
        (var-set total-items (+ (var-get total-items) u1))
        (ok true))
      (err u1))))  ;; Error code 1: Description too long

;; Remove an item from the platform
(define-public (remove-item)
  (let ((caller tx-sender))
    (if (is-some (map-get? items caller))
      (begin
        (map-delete items caller)
        (var-set total-items (- (var-get total-items) u1))
        (ok true))
      (err u2))))  ;; Error code 2: No item found for user

;; Update user reputation
(define-public (update-reputation (user principal) (points int))
  (let ((current-reputation (default-to u0 (map-get? user-reputation user)))
        (new-reputation (+ current-reputation (to-uint points))))
    (if (<= new-reputation MAX_REPUTATION_POINTS)
      (begin
        (map-set user-reputation user new-reputation)
        (ok true))
      (err u3))))  ;; Error code 3: Reputation exceeds maximum

;; Get user reputation
(define-read-only (get-reputation (user principal))
  (ok (default-to u0 (map-get? user-reputation user))))

;; Get total number of items on the platform
(define-read-only (get-total-items)
  (ok (var-get total-items)))