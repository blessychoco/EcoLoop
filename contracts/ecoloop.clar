;; EcoLoop Smart Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_ITEM_NOT_FOUND (err u2))
(define-constant ERR_INVALID_INPUT (err u3))
(define-constant ERR_ITEM_ALREADY_EXISTS (err u4))
(define-constant MAX_DESCRIPTION_LENGTH u256)
(define-constant MAX_REPUTATION_POINTS u1000000)
(define-constant REPUTATION_THRESHOLD u100)
(define-constant MAX_ITEMS_PER_USER u1000)

;; Data variables
(define-data-var total-items uint u0)

;; Data maps
(define-map items 
  { owner: principal, id: uint } 
  { description: (string-ascii 256), status: (string-ascii 20) })
(define-map user-data
  principal
  { reputation: uint, items-count: uint })

;; Private functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER))

(define-private (get-and-increment-user-items (user principal))
  (let ((user-info (default-to { reputation: u0, items-count: u0 } (map-get? user-data user))))
    (if (< (get items-count user-info) MAX_ITEMS_PER_USER)
      (let ((new-count (+ (get items-count user-info) u1)))
        (map-set user-data 
          user 
          (merge user-info { items-count: new-count }))
        new-count)
      u0))) ;; Return 0 if max items reached, which will be caught in add-item

;; Public functions
(define-public (add-item (description (string-ascii 256)))
  (let ((caller tx-sender)
        (item-id (get-and-increment-user-items caller)))
    (if (is-eq item-id u0)
      ERR_INVALID_INPUT
      (if (> (len description) MAX_DESCRIPTION_LENGTH)
        ERR_INVALID_INPUT
        (if (is-some (map-get? items {owner: caller, id: item-id}))
          ERR_ITEM_ALREADY_EXISTS
          (begin
            (map-set items 
              {owner: caller, id: item-id}
              {description: description, status: "available"})
            (var-set total-items (+ (var-get total-items) u1))
            (ok item-id)))))))

(define-public (update-item-status (item-id uint) (new-status (string-ascii 20)))
  (let ((caller tx-sender)
        (user-info (default-to { reputation: u0, items-count: u0 } (map-get? user-data caller))))
    (if (and (> item-id u0) (<= item-id (get items-count user-info)))
      (match (map-get? items {owner: caller, id: item-id})
        item (begin
          (map-set items 
            {owner: caller, id: item-id}
            (merge item {status: new-status}))
          (ok true))
        ERR_ITEM_NOT_FOUND)
      ERR_INVALID_INPUT)))

(define-public (remove-item (item-id uint))
  (let ((caller tx-sender)
        (user-info (default-to { reputation: u0, items-count: u0 } (map-get? user-data caller))))
    (if (and (> item-id u0) (<= item-id (get items-count user-info)))
      (match (map-get? items {owner: caller, id: item-id})
        item (begin
          (map-delete items {owner: caller, id: item-id})
          (var-set total-items (- (var-get total-items) u1))
          (map-set user-data 
            caller 
            (merge user-info { items-count: (- (get items-count user-info) u1) }))
          (ok true))
        ERR_ITEM_NOT_FOUND)
      ERR_INVALID_INPUT)))

(define-public (update-reputation (user principal) (points int))
  (if (is-contract-owner)
    (let ((current-data (default-to { reputation: u0, items-count: u0 } (map-get? user-data user)))
          (new-reputation (+ (get reputation current-data) (to-uint points))))
      (if (<= new-reputation MAX_REPUTATION_POINTS)
        (begin
          (map-set user-data 
            user 
            (merge current-data { reputation: new-reputation }))
          (ok new-reputation))
        ERR_INVALID_INPUT))
    ERR_UNAUTHORIZED))

;; Read-only functions
(define-read-only (get-item (owner principal) (item-id uint))
  (map-get? items {owner: owner, id: item-id}))

(define-read-only (get-user-data (user principal))
  (default-to { reputation: u0, items-count: u0 } (map-get? user-data user)))

(define-read-only (get-total-items)
  (ok (var-get total-items)))

(define-read-only (can-perform-action (user principal))
  (>= (get reputation (get-user-data user)) REPUTATION_THRESHOLD))