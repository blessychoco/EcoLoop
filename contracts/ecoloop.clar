;; EcoLoop Smart Contract

;; Define data variables
(define-data-var total-items uint u0)
(define-map items principal (string-ascii 256))
(define-map user-reputation principal uint)

;; Add a new item to the platform
(define-public (add-item (item-description (string-ascii 256)))
  (let ((caller tx-sender))
    (begin
      (map-set items caller item-description)
      (var-set total-items (+ (var-get total-items) u1))
      (ok true))))

;; Remove an item from the platform
(define-public (remove-item)
  (let ((caller tx-sender))
    (begin
      (map-delete items caller)
      (var-set total-items (- (var-get total-items) u1))
      (ok true))))

;; Update user reputation
(define-public (update-reputation (user principal) (points int))
  (let ((current-reputation (default-to u0 (map-get? user-reputation user))))
    (map-set user-reputation user (+ current-reputation (to-uint points)))
    (ok true)))

;; Get user reputation
(define-read-only (get-reputation (user principal))
  (default-to u0 (map-get? user-reputation user)))

;; Get total number of items on the platform
(define-read-only (get-total-items)
  (ok (var-get total-items)))