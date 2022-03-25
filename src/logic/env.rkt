#lang racket
(require redex/reduction-semantics
         "grammar.rkt")
(provide (all-defined-out))

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-with-hook : Hook -> Env

  [(env-with-hook Hook)
   (Hook RootUniverse () () ())]
  )

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-hook : Env -> Hook

  [(env-hook (Hook Universe VarBinders Substitution Hypotheses)) Hook]
  )

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-hypotheses : Env -> Hypotheses

  [(env-hypotheses (Hook Universe VarBinders Substitution Hypotheses)) Hypotheses]
  )

(define-metafunction formality-logic
  ;; Returns the `VarId -> Universe` mapping from the environment
  env-var-binders : Env -> VarBinders

  [(env-var-binders (Hook Universe VarBinders Substitution Hypotheses)) VarBinders]
  )

(define-metafunction formality-logic
  ;; Returns the substitution from the environment -- i.e., the currently inferred values
  ;; for any existential variables
  env-substitution : Env -> Substitution

  [(env-substitution (Hook Universe VarBinders Substitution Hypotheses)) Substitution]
  )

(define-metafunction formality-logic
  ;; Returns the current maximum universe in the environment
  env-universe : Env -> Universe

  [(env-universe (Hook Universe VarBinders Substitution Hypotheses)) Universe]
  )

(define-metafunction formality-logic
  ;; Returns the existential `VarId` from the environment
  existential-vars-in-env : Env -> VarIds

  [(existential-vars-in-env Env)
   (existential-vars-from-binders VarBinders)
   (where/error VarBinders (env-var-binders Env))
   ]
  )

(define-metafunction formality-logic
  ;; Filters out universal (ForAll) binders and returns just the VarIds of the existential ones.
  existential-vars-from-binders : VarBinders -> VarIds

  [(existential-vars-from-binders ()) ()]

  [(existential-vars-from-binders ((_ ForAll _) VarBinder_2 ...))
   (existential-vars-from-binders (VarBinder_2 ...))]

  [(existential-vars-from-binders ((VarId_1 Exists _) VarBinder_2 ...))
   (VarId_1 VarId_2 ...)
   (where/error (VarId_2 ...) (existential-vars-from-binders (VarBinder_2 ...)))]

  )

(define-metafunction formality-logic
  ;; Extend `Env`, mapping the names in `VarIds` to the current universe
  env-with-vars-in-current-universe : Env Quantifier VarIds -> Env

  [(env-with-vars-in-current-universe Env Quantifier (VarId ...))
   (Hook Universe ((VarId Quantifier Universe) ... VarBinder ...) Substitution Hypotheses)
   (where/error (Hook Universe (VarBinder ...) Substitution Hypotheses) Env)
   ]
  )

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-with-hypotheses : Env Hypotheses -> Env

  [(env-with-hypotheses Env ()) Env]

  [(env-with-hypotheses Env (Hypothesis_0 Hypothesis_1 ...))
   (env-with-hypotheses Env_1 (Hypothesis_1 ...))
   (where/error Env_1 (env-with-hypothesis Env Hypothesis_0))
   ]
  )

(define-metafunction formality-logic
  ;; Adds a hypothesis (if not already present)
  env-with-hypothesis : Env Hypothesis -> Env

  [(env-with-hypothesis Env Hypothesis_1)
   Env
   (where #t (in? Hypothesis_1 (env-hypotheses Env)))
   ]

  [(env-with-hypothesis (Hook Universe VarBinders Substitution (Hypothesis_0 ...)) Hypothesis_1)
   (Hook Universe VarBinders Substitution (Hypothesis_0 ... Hypothesis_1))
   ]

  )

(define-metafunction formality-logic
  ;; Returns an `Env` where `VarId` is guaranteed to contain only elements from
  ;; `Universe`.
  env-with-var-limited-to-universe : Env VarId Universe -> Env

  [(env-with-var-limited-to-universe Env VarId Universe_max)
   (Hook Universe (VarBinder_0 ... (VarId Quantifier Universe_new) VarBinder_1 ...) Substitution Hypotheses)
   (where/error (Hook Universe (VarBinder_0 ... (VarId Quantifier Universe_old) VarBinder_1 ...) Substitution Hypotheses) Env)
   (where/error Universe_new (min-universe Universe_old Universe_max))
   ]
  )

(define-metafunction formality-logic
  ;; Returns an `Env` where each of the given `VarId`s is guaranteed to
  ;; contain only elements from `Universe`.
  env-with-vars-limited-to-universe : Env (VarId ...) Universe -> Env

  [(env-with-vars-limited-to-universe Env () Universe_max)
   Env]

  [(env-with-vars-limited-to-universe Env (VarId_0 VarId_1 ...) Universe_max)
   (env-with-vars-limited-to-universe Env (VarId_1 ...) Universe_max)
   (where (UniverseId 0) (universe-of-var-in-env Env VarId_0))]

  [(env-with-vars-limited-to-universe Env (VarId_0 VarId_1 ...) Universe_max)
   (env-with-vars-limited-to-universe Env_1 (VarId_1 ...) Universe_max)
   (where/error Env_1 (env-with-var-limited-to-universe Env VarId_0 Universe_max))
   ]
  )

(define-metafunction formality-logic
  ;; Returns an environment where the current universe is incremented, and returns
  ;; this new universe.
  env-with-incremented-universe : Env -> Env

  [(env-with-incremented-universe Env)
   (Hook Universe_new VarBinders Substitution Hypotheses)

   (where/error (Hook Universe VarBinders Substitution Hypotheses) Env)
   (where/error Universe_new (next-universe Universe))
   ]

  )

(define-metafunction formality-logic
  ;; Finds the declared universe of `VarId` in the given environment.
  ;;
  ;; If `VarId` is not found in the `Env`, returns the root universe. This is a useful
  ;; default for random user-given names like `i32` or `Vec`.
  universe-of-var-in-env : Env VarId -> Universe

  [(universe-of-var-in-env Env VarId)
   Universe
   (where (_ ... (VarId Quantifier Universe) _ ...) (env-var-binders Env))]

  [; Default is to consider random type names as "forall" constants in root universe
   (universe-of-var-in-env Env VarId_!_1)
   RootUniverse
   (where ((VarId_!_1 _ _) ...) (env-var-binders Env))]

  )


(define-metafunction formality-logic
  ;; True if this variable is an existential variable defined in the environment.
  env-contains-existential-var : Env VarId -> boolean

  [(env-contains-existential-var Env VarId)
   #t
   (where (_ ... (VarId Exists Universe) _ ...) (env-var-binders Env))]

  [(env-contains-existential-var Env VarId)
   #f]

  )

(define-metafunction formality-logic
  ;; Increments a universe to return the next largest universe.
  next-universe : Universe -> Universe

  [(next-universe (UniverseId natural))
   (UniverseId ,(+ 1 (term natural)))]
  )

(define-metafunction formality-logic
  ;; True if the given variable appears free in the given term.
  appears-free : VarId any -> boolean

  [(appears-free VarId any)
   ,(not (alpha-equivalent? formality-logic (term any) (term any_1)))
   (where/error any_1 (substitute any VarId (TyRigid VarId ())))
   ]
  )

(define-metafunction formality-logic
  ;; Returns the set of variables that appear free in the given term.
  free-variables : any -> (VarId ...)

  [(free-variables (Quantifier ((ParameterKind VarId_bound) ...) any))
   ,(set-subtract (term VarIds_free) (term (VarId_bound ...)))
   (where/error VarIds_free (free-variables any))]

  [(free-variables VarId)
   (VarId)]

  [; The `c` in `(TyRigid c ())` is not a variable but a constant.
   (free-variables (TyRigid _ Substitution))
   (free-variables Substitution)]

  [(free-variables (LtApply _))
   ()]

  [(free-variables (any ...))
   ,(apply set-union (term (() VarIds ...)))
   (where/error (VarIds ...) ((free-variables any) ...))
   ]

  [(free-variables _)
   ()]

  )

(define-metafunction formality-logic
  ;; The "grammar" for predicates is just *any term* -- that's not very
  ;; useful, and extension languages refine it. When matching against predicates,
  ;; then, we can use this function to avoid matching on other kinds of goals.
  is-predicate-goal? : Goal -> boolean

  [(is-predicate-goal? BuiltinGoal) #f]
  [(is-predicate-goal? Relation) #f]
  [(is-predicate-goal? _) #t]
  )

(define-metafunction formality-logic
  ;; Returns the set of universally quantified variables from
  ;; within the term -- this excludes global constants like
  ;; adt names. So e.g. if you have `(TyRigid Vec ((! X)))`,
  ;; this would return `(X)`.
  placeholder-variables : Term -> (VarId ...)

  [(placeholder-variables (! VarId))
   (VarId)]

  [(placeholder-variables (Term ...))
   ,(apply set-union (term (() VarIds ...)))
   (where/error (VarIds ...) ((placeholder-variables Term) ...))
   ]

  [(placeholder-variables _)
   ()]

  )

(define-metafunction formality-logic
  ;; Boolean operator
  not? : boolean -> boolean
  [(not? #f) #t]
  [(not? #t) #f]
  )

(define-metafunction formality-logic
  ;; Boolean operator
  all? : boolean ... -> boolean
  [(all? #t ...) #t]
  [(all? _ ...) #f]
  )

(define-metafunction formality-logic
  ;; Boolean operator
  any? : boolean ... -> boolean
  [(any? _ ... #t _ ...) #t]
  [(any? _ ...) #f]
  )

(define-metafunction formality-logic
  ;; Boolean operator
  in? : Term (Term ...) -> boolean
  [(in? Term_0 (_ ... Term_1 _ ...))
   #t
   (where #t ,(alpha-equivalent? (term Term_0) (term Term_1)))
   ]

  [(in? _ _)
   #f
   ]
  )

(define-metafunction formality-logic
  ;; Returns the smallest of the various universes provided
  min-universe : Universe ... -> Universe
  [(min-universe (UniverseId number) ...)
   (UniverseId ,(apply min (term (number ...))))
   ])

(define-metafunction formality-logic
  ;; Returns the smallest of the various universes provided
  max-universe : Universe ... -> Universe
  [(max-universe (UniverseId number) ...)
   (UniverseId ,(apply max (term (number ...))))
   ])

(define-metafunction formality-logic
  ;; True if `Universe_0` includes all values of `Universe_1`
  universe-includes : Universe_0 Universe_1 -> boolean
  [(universe-includes (UniverseId number_0) (UniverseId number_1))
   ,(>= (term number_0) (term number_1))])

(define-metafunction formality-logic
  ;; Flatten a list of lists.
  flatten : ((Term ...) ...) -> (Term ...)

  [(flatten ((Term ...) ...)) (Term ... ...)]
  )