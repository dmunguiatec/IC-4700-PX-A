IC-4700 Lenguajes de programación  
Prof. Diego Munguia Molina  
IC-AL
---
# Proyecto Prolog en Racket

## Objetivos de aprendizaje

1. Modelar el funcionamiento interno de los principios de programación lógica en un lenguaje de programación (III).
2. Programar soluciones a problemas computacionales utilizando el lenguaje de programación Racket (III).

## Descripción

Queremos desarrollar una implementación en Racket de un intérprete para un subconjunto del lenguaje de programación lógica 
Prolog que llamaremos `byopl`.

## Requerimientos funcionales

Nuestro intérprete funcionará sobre el REPL de DrRacket, y estará implementado como una biblioteca de funciones racket. La persona usuaria define un programa como una lista de hechos y reglas, y luego evalúa consultas llamando a una función `?-`.

```scheme
> (define dbz
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
    (:- (ancestra ?x ?y) ((ancestra ?x ?p) (progenitora ?p ?y)))
    )
  )
> (?- '(padre ?x pan))
'((?x . gohan))
> (?- '(progenitora ?x goten))
'((?x . goku) (?x . chichi))
> (?- '(igual a b))
#f
> (?- '(igual a a))
'((?x . a))
```

Vamos a asumir que la entrada siempre es correcta y está bien formada. No es necesario hacer validaciones sintácticas o semánticas.

## Lenguaje

Especificamos a continuación los elementos del lenguaje que vamos a implementar.

### Variables

Las variables se representan como un símbolo que inicia con signo de pregunta. Por ejemplo `'?x`, `'?y`, `'?mi-variable`.

### Hechos

Los hechos se representan como una lista de símbolos, donde el primer símbolo corresponde al *functor* y los siguientes símbolos corresponden a los valores relacionados por el *functor*.

Por ejemplo, el hecho

```scheme
'(padre bardock goku)
```

Es equivalente a `padre(bardock, goku).` en prolog.

### Reglas

Las reglas se representan como una lista compuesta de la siguiente manera

```scheme
'(:- <encabezado> (<condición_1> <condición_2> ... <condición_n)>)
```

Donde `<encabezado>` y `<condición_i>` corresponden a relaciones. Por ejemplo la regla

```scheme
'(:- (ancestra ?x ?y) ((ancestra ?x ?p) (progenitora ?p ?y)))
```

corresponde a `ancestra(X, Y) :- ancestra(X, P), progenitora(P, Y).` en prolog.

## Arquitectura

Además de la función de consulta `?-`, se recomienda implementar las siguientes funciones que servirán como pilares estructurales para resolver consultas:

### Unificar

Implementa el algoritmo de unificación y retorna la lista de asociaciones entre variables y valores o `#f` cuando no logra unificar.

```scheme
(unificar términoA términoB asociaciones)
```

Por ejemplo

```scheme
> (unificar '(ancestro ?x pan) '(ancestro ?x ?y) '())
'((?x . ?_1) (?x . ?_1) (?y . pan))
> (unificar '(igual a b) '(igual ?x ?x))
#f
```

### Asociar

Agrega una nueva asociación entre variable y valor a una lista de asociaciones

```scheme
(asociar variable valor asociaciones)
```

Por ejemplo

```scheme
> (asociar '?y pan '())
'((?y . pan))
> (asociar '?x 'goku '((?y . pan)))
'((?y . pan) (?x . goku))
```

### Instanciar

Intenta reemplazar las variables en un relación por sus valores según la tabla de asociaciones.

```scheme
(instanciar relación asociaciones)
```

Por ejemplo

```scheme
> (instanciar '(padre ?p pan) '((?_1 . ?_2) (?x . ?_2) (?p . ?_3) (?y . ?_3)))
'(padre ?_3 pan)
> (instanciar '((ancestro ?x ?p) (padre ?p ?y)) '((?x . ?_1) (?x . ?_1) (?y . pan)))
'((ancestro ?_1 ?p) (padre ?p pan))
```

### Buscar

Implementa la búsqueda por *backtracking*. Calcula todas las soluciones posibles en una sola llamada.

```scheme
(buscar meta programa incógnitas asociaciones)
```

Por ejemplo:

```
> (buscar '(ancestro ?x pan) dbz '(?x) '())
'((?x . bardock) (?x . goku) (?x . gohan) (?x . chichi) (?x . videl))
```

### Variables internas

Puesto que en programación funcional no modificamos estado ni mantenemos variables globales, es necesario poder calcular cuál es la próxima variable interna a generar con base en las asociaciones ya existentes.

```scheme
(generar-variable-interna asociaciones)
```

Por ejemplo

```scheme
> (generar-variable-interna '((?r . 0) (?z . a) (?y . b) (?x . c)))
'?_1
> (generar-variable-interna '((?r . ?_1) (?_1 . ?_2)))
'?_3
> (generar-variable-interna '((?r . ?_1) (?_1 . ?_2) (?_3 . b)))
'?_4
```            

### Accesores para estructuras de datos

Facilitan la abstracción de las distintas estructuras de datos requeridas ya que todas son implementadas con listas.

```sceheme
(es-regla? relación)
(encabezado-regla regla)
(condiciones-regla regla)

(es-hecho? relación)
(functor hecho)
(términos hecho)
(aridad hecho)

(es-variable? término)
(es-variable-interna? variable)
(es-átomo? término)
```

Por ejemplo

```scheme
> (es-regla? '(:- (progenitora ?x  ?y) ((padre ?x ?y))))
#t
> (es-regla? '(madre bulma trunks))
#f
> (es-regla? '())
#f
> (encabezado-regla '(:- (progenitora ?x  ?y) ((padre ?x ?y))))
'(progenitora ?x  ?y)
> (condiciones-regla '(:- (progenitora ?x  ?y) ((padre ?x ?y))))
'((padre ?x ?y))
> (es-hecho? '(:- (progenitora ?x  ?y) ((padre ?x ?y))))
#f
> (es-hecho? '(madre bulma trunks))
#t
> (es-hecho? '())
#f
> (functor '(padre goku gohan))
'padre
> (términos '(padre goku gohan))
'(goku gohan)
> (aridad '(padre goku gohan))
2
> (es-variable? '?x)
#t
> (es-variable? '?_5)
#t
> (es-variable? 1)
#f
> (es-variable? 'goku)
#f
> (es-átomo? 'goku)
#t
> (es-átomo? '?x)
#f
> (es-átomo? 1)
#f
> (es-variable-interna? '?_1)
#t
> (es-variable-interna? '?x)
#f
```

## Ambiente de desarrollo

DrRacket  
Se recomienda el uso de la función `trace` para observar la trazabilidad de llamadas entre funciones, particularmente

```scheme
(trace unificar)
(trace asociar)
(trace instanciar)
(trace buscar)
```

## Metodología

* El proyecto se trabajará en equipos de entre una y tres personas.
* El proyecto se desarrollará en el transcurso de dos semanas.
* El proyecto se desarrollará en Racket siguiendo el paradigma funcional.
* El proyecto se entregará en el repositorio de git facilitado por la persona docente.
* El proyecto será evaluado a través de pruebas automatizadas aplicadas al código entregado y a través de una prueba escrita individual aplicada a todas las personas miembros del equipo.

## Rúbricas de evaluación

**Código producido** (50%)  
- Hay producción de código para implementar los requerimientos funcionales (15%)
- El código producido se apega al paradigma de orientación a objetos (15%)
- El código producido pasa los casos de prueba (20%)

**Defensa del proyecto** (50%)
- Prueba escrita de defensa del proyecto (50%)
