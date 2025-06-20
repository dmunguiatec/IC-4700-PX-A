#lang racket

(require rackunit)
(require rackunit/text-ui)
(require racket/trace)

;; Implementación del intérprete
(define (?- consulta programa)
  #f)
           
;; Casos de prueba
(define pruebas-estructuras-datos
  (test-suite
   "Estructuras de datos"
   (test-case "Es regla? Caso positivo"
              (check-true
               (es-regla? '(:- (progenitora ?x  ?y) ((padre ?x ?y))))))
   (test-case "Es regla? Caso negativo"
              (check-false
               (es-regla? '(madre bulma trunks))))
   (test-case "Es regla? Lista vacía"
              (check-false
               (es-regla? '())))
   (test-case "Encabezado de regla"
              (check-equal?
               (encabezado-regla '(:- (progenitora ?x  ?y) ((padre ?x ?y))))
               '(progenitora ?x  ?y)))
   (test-case "Condiciones de regla"
              (check-equal?
               (condiciones-regla '(:- (progenitora ?x  ?y) ((padre ?x ?y))))
               '((padre ?x ?y))))
   (test-case "Es hecho? Caso negativo"
              (check-false
               (es-hecho? '(:- (progenitora ?x  ?y) ((padre ?x ?y))))))
   (test-case "Es hecho? Caso positivo"
              (check-true
               (es-hecho? '(madre bulma trunks))))
   (test-case "Es hecho? Lista vacía"
              (check-false
               (es-hecho? '())))
   (test-case "Functor de hecho"
              (check-equal?
               (functor '(padre goku gohan))
               'padre))
   (test-case "Términos de hecho"
              (check-equal?
               (términos '(padre goku gohan))
               '(goku gohan)))
   (test-case "Aridad de hecho"
              (check-equal?
               (aridad '(padre goku gohan))
               2))
   (test-case "Es variable? Con variable"
              (check-true
               (es-variable? '?x)))
   (test-case "Es variable? Con variable interna"
              (check-true
               (es-variable? '?_5)))
   (test-case "Es variable? Con número"
              (check-false
               (es-variable? 1)))
   (test-case "Es variable? Con átomo"
              (check-false
               (es-variable? 'goku)))
   (test-case "Es átomo? Con átomo"
              (check-true
               (es-átomo? 'goku)))
   (test-case "Es átomo? Con variable"
              (check-false
               (es-átomo? '?x)))
   (test-case "Es átomo? Con número"
              (check-false
               (es-átomo? 1)))
   )
  )

(define pruebas-asociaciones
  (test-suite
   "Asociaciones"
   (test-case "Asociar variable, valor es var, existente es var"
              (check-equal?
               (asociar '?r '?p '((?r . ?q) (?z . a)))
               '((?r . ?q) (?z . a) (?r . ?_1) (?p . ?_1) (?q . ?_1))))
   (test-case "Asociar variable, valor es var, existente es null"
              (check-equal?
               (asociar '?a '?b '((?x . ?_1)))
               '((?x . ?_1) (?a . ?_2) (?b . ?_2))))
   (test-case "Asociar variable, valor es var, existente es átomo"
              (check-equal?
               (asociar '?r '?q '((?y . b) (?r . c)))
               '((?y . b) (?r . c) (?r . ?_1) (?q . ?_1) (?_1 . c))))
   (test-case "Asociar variable, valor es átomo, existente es var"
              (check-equal?
               (asociar '?r 'c '((?y . b) (?r . ?q)))
               '((?y . b) (?r . ?q) (?q . c))))
   (test-case "Asociar variable, valor es átomo, existente es null"
              (check-equal?
               (asociar '?r 'c '((?y . b)))
               '((?y . b) (?r . c))))
   (test-case "Asociar variable, valor es átomo, existente es átomo y coinciden"
              (check-true
               (asociar '?r 'c '((?y . b) (?r . c)))))
   (test-case "Asociar variable, valor es átomo, existente es átomo y no coinciden"
              (check-false
               (asociar '?r 'c '((?y . b) (?r . a)))))
   (test-case "Es variable interna? positivo"
              (check-true
               (es-variable-interna? '?_1)))
   (test-case "Es variable interna? negativo"
              (check-false
               (es-variable-interna? '?x)))
   (test-case "Generar variable interna inicial"
              (check-equal?
               (generar-variable-interna '((?r . 0) (?z . a) (?y . b) (?x . c)))
               '?_1))
   (test-case "Generar variable interna siguiente lado izq"
              (check-equal?
               (generar-variable-interna '((?r . ?_1) (?_1 . ?_2) (?_2 . b)))
               '?_3))
   (test-case "Generar variable interna siguiente lado der"
              (check-equal?
               (generar-variable-interna '((?r . ?_1) (?_1 . ?_2)))
               '?_3))
   )
  )

(define pruebas-unificación
  (test-suite
   "Unificación"
   (test-case "Instanciar variables en un hecho"
              (check-equal?
               (instanciar '(padre goku ?y) '((?z . a) (?y . goten) (?x . c)))
               '(padre goku goten)))
   (test-case "Instanciar variables en una regla"
              (check-equal?
               (instanciar '(:- (progenitora ?x  ?y) ((padre ?x ?y)))
                           '((?z . a) (?x . goku)))
               '(:- (progenitora goku  ?y) ((padre goku ?y)))))
   (test-case "Instanciar variables internas en una regla"
              (check-equal?
               (instanciar '(:- (progenitora ?x  ?y) ((padre ?x ?y)))
                           '((?z . a) (?x . ?_1)))
               '(:- (progenitora ?_1  ?y) ((padre ?_1 ?y)))))
   (test-case "Instanciar variables sin asociación en una regla"
              (check-equal?
               (instanciar '(:- (progenitora ?x  ?y) ((padre ?x ?y)))
                           '((?z . a)))
               '(:- (progenitora ?x  ?y) ((padre ?x ?y)))))
   (test-case "Unificar símbolos iguales"
              (check-true
               (unificar 'a 'a '())))
   (test-case "Unificar símbolos diferentes"
              (check-false
               (unificar 'a 'b '())))
   (test-case "Unificar variable con símbolo"
              (check-equal?
               (unificar '?x 'a '())
               '((?x . a))))
   (test-case "Unificar símbolo con variable"
              (check-equal?
               (unificar 'a '?x '())
               '((?x . a))))
   (test-case "Unificar variable con variable"
              (check-equal?
               (unificar '?x '?y '())
               '((?x . ?_1) (?y . ?_1))))
   (test-case "Unificar términos caso 1"
              (check-equal?
               (unificar '(ancestro ?x pan) '(ancestro ?x ?y) '())
               '((?x . ?_1) (?x . ?_1) (?y . pan))))
   (test-case "Unificar términos caso 2"
              (check-equal?
               (unificar '(ancestro ?_1 ?p) '(ancestro ?x ?y) '())
               '((?_1 . ?_2) (?x . ?_2) (?p . ?_3) (?y . ?_3))))
   (test-case "Unificar términos caso 2"
              (check-equal?
               (unificar '(ancestro ?_1 ?p) '(ancestro ?x ?y) '())
               '((?_1 . ?_2) (?x . ?_2) (?p . ?_3) (?y . ?_3))))
   (test-case "Unificar términos caso 3"
              (check-equal?
               (unificar '(padre ?_2 ?_3) '(padre goku gohan) '())
               '((?_2 . goku) (?_3 . gohan))))
   )
  )

(define (same-elements? lst1 lst2)
  (equal? (set lst1) (set lst2)))

(define pruebas-consulta
  (test-suite
   "Consultas"
   (test-case "Consulta igual true"
              (check-equal?
               (?- '(igual a a) dbz)
               '((?x . a))))
   (test-case "Consulta igual false"
              (check-false
               (?- '(igual a b) dbz)))
   (test-case "Consulta hecho"
              (check-true
               (same-elements?
                (?- '(padre goku ?hijo) dbz)
                '((?hijo . gohan) (?hijo . goten)))))
   (test-case "Consulta regla simple"
              (check-true
               (same-elements?
                (?- '(progenitora ?x goten) dbz)
                '((?x . goku) (?x . chichi)))))
   (test-case "Consulta regla recursiva"
              (check-true
               (same-elements?
                (?- '(ancestra ?x pan) dbz)
                '((?x . bardock) (?x . goku) (?x . gohan) (?x . chichi) (?x . videl)))))
   )
  )
 
;; Programa de prueba
(define dbz
  '((igual ?x ?x)
    (padre bardock goku)
    (padre goku gohan)
    (padre goku goten)
    (padre bardock raditz)
    (padre vegeta trunks)
    (padre gohan pan)
    (madre chichi goten)
    (madre bulma trunks)
    (madre chichi gohan)
    (madre videl pan)
    (:- (progenitora ?x  ?y) ((padre ?x ?y)))
    (:- (progenitora ?x  ?y) ((madre ?x ?y)))
    (:- (ancestra ?x ?y) ((progenitora ?x ?y)))
    (:- (ancestra ?x ?y) ((progenitora ?x ?p) (ancestra ?p ?y)))
    )
  )

(run-tests pruebas-estructuras-datos)
(run-tests pruebas-asociaciones)
(run-tests pruebas-unificación)
(run-tests pruebas-consulta)

(trace unificar)
(trace asociar)
(trace instanciar)
(trace buscar)
