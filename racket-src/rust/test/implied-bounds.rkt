#lang racket
(require redex/reduction-semantics
         "../../util.rkt"
         "../grammar.rkt"
         "../prove.rkt"
         )

;; Various tests that check the requirements that where clauses be well-formed.

(module+ test

  (redex-let*
   formality-rust

   [([Rust/CrateItemDecl ...] (term [(trait Foo[(type T)] where [(T : Bar()) (Self : Bar())] {})
                                     (trait Bar[] where [] {})]))
    (Rust/Program_not-expanded (term ([(crate C { Rust/CrateItemDecl ... })]
                                      C)))
    (Rust/Program_expanded (term ([(crate C { (feature expanded-implied-bounds)
                                              Rust/CrateItemDecl ...
                                              })]
                                  C)))
    ]

   (traced '()
           ; Knowing that `A: Foo<B>` implies that `A: Bar`
           (test-equal
            #t
            (term (rust:can-prove-where-clause-in-program
                   Rust/Program_not-expanded
                   (∀ ((type A) (type B))
                      where [(A : Foo[B])]
                      (A : Bar[]))))))

   (traced '()
           ; Knowing that `A: Foo<B>` does not imply `B: Bar`
           (test-equal
            #f
            (term (rust:can-prove-where-clause-in-program
                   Rust/Program_not-expanded
                   (∀ ((type A) (type B))
                      where [(A : Foo[B])]
                      (B : Bar[]))))))

   (traced '()
           ; Knowing that `A: Foo<B>` implies `B: Bar` w/ expanded-implied-bounds
           (test-equal
            #t
            (term (rust:can-prove-where-clause-in-program
                   Rust/Program_expanded
                   (∀ ((type A) (type B))
                      where [(A : Foo[B])]
                      (B : Bar[]))))))
   )

  (redex-let*
   formality-rust

   [([Rust/CrateItemDecl ...] (term [(trait Foo[(lifetime l) (type T)]
                                            where ((T : l)
                                                   (Self : l))
                                            {})]))

    (Rust/Program_not-expanded (term ([(crate C { Rust/CrateItemDecl ... })]
                                      C)))
    (Rust/Program_expanded (term ([(crate C { (feature expanded-implied-bounds)
                                              Rust/CrateItemDecl ... })]
                                  C)))
    ]

   (; Knowing that `A: Foo<'a, B>` implies that `A: 'a`
    traced '()
           (test-equal
            #t
            (term (rust:can-prove-where-clause-in-program
                   Rust/Program_not-expanded
                   (∀ ((type A) (lifetime a) (type B))
                      where [(A : Foo[a B])]
                      (A : a))))))

   (; Knowing that `A: Foo<'a, B>` does not imply that `B: 'a`
    traced '()
           (test-equal
            #f
            (term (rust:can-prove-where-clause-in-program
                   Rust/Program_not-expanded
                   (∀ ((type A) (lifetime a) (type B))
                      where [(A : Foo[a B])]
                      (B : a))))))

   (; Knowing that `A: Foo<'a, B>` implies `B: 'a` w/ expanded-implied-bounds
    traced '()
           (test-equal
            #t
            (term (rust:can-prove-where-clause-in-program
                   Rust/Program_expanded
                   (∀ ((type A) (lifetime a) (type B))
                      where [(A : Foo[a B])]
                      (B : a))))))
   )
  )