#lang racket
(require redex/reduction-semantics
         "../decl-to-clause.rkt"
         "../grammar.rkt"
         "../../ty/grammar.rkt"
         "../../ty/solve.rkt"
         "../../util.rkt")

(module+ test
  ;; Program:
  ;;
  ;; trait Debug { }
  ;; impl Debug for i32 { }
  (redex-let*
   formality-decl

   ((TraitDecl (term (Debug (trait ((TyKind Self)) () ()))))
    (TraitImplDecl (term (impl () (Debug ((scalar-ty i32))) () ())))
    (CrateDecl (term (TheCrate (crate (TraitDecl TraitImplDecl)))))
    (Env (term (env-with-crate-decl EmptyEnv CrateDecl)))
    )

   (traced '()
           (test-equal
            (judgment-holds (prove Env
                                   (Implemented (Debug ((scalar-ty i32))))
                                   EnvSubstitution)
                            EnvSubstitution)
            (term ((Env ())))))
   )
  )
