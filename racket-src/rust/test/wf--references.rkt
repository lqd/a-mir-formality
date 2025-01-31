#lang racket
(require redex/reduction-semantics
         "../../util.rkt"
         "../../ty/user-ty.rkt"
         "../grammar.rkt"
         "../prove.rkt"
         "../libcore.rkt"
         )

(module+ test

  (; &'a T is WF if T: 'a...
   traced '()
          (test-equal
           (term (rust:can-prove-goal-in-program
                  ([libcore] core)
                  (∀ [(type T) (lifetime a)]
                     (implies [(T -outlives- a)]
                              (well-formed (type (user-ty (& a T))))))))
           #t
           ))

  (; ...and if `T: 'b` and `'b: 'a`...
   traced '()
          (test-equal
           (term (rust:can-prove-goal-in-program
                  ([libcore] core)
                  (∀ [(type T) (lifetime a) (lifetime b)]
                     (implies [(T -outlives- b) (b -outlives- a)]
                              (well-formed (type (user-ty (& a T))))))))
           #t
           ))

  (; ...but not if `T` and `'a` have no relationship.
   traced '()
          (test-equal
           (term (rust:can-prove-goal-in-program
                  ([libcore] core)
                  (∀ [(type T) (lifetime a)]
                     (implies []
                              (well-formed (type (user-ty (& a T))))))))
           #f
           ))

  (; If we know that `(T,): 'a`, we know that `T: 'a`
   traced '()
          (test-equal
           (term (rust:can-prove-goal-in-program
                  ([libcore] core)
                  (∀ [(type T) (lifetime a)]
                     (implies [((user-ty (tuple T)) -outlives- a)]
                              (well-formed (type (user-ty (& a T))))))))
           #t
           ))

  )