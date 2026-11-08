# Island of Flavors

Juego de combate 2D lateral en tres carriles: despliegas unidades con un recurso que se recarga solo para destruir el obstáculo enemigo mientras proteges tu base. Motor: **Godot 4** (GDScript), pensado para **móvil en horizontal**.

Estado actual: **prototipo gris** (Fase 1 del plan). Formas grises, sin arte ni sonido.

## Cómo abrirlo

1. Instala [Godot 4.4](https://godotengine.org/download) o superior (versión estándar, no .NET).
2. En Godot, *Importar* y elige `project.godot`.
3. Pulsa *Ejecutar* (F5). La escena principal es `escenas/batalla/batalla.tscn`.

Con ratón: clic en un botón del mazo para invocar. Para el explosivo, clic en su botón y luego clic en el carril.

## Estructura

```
datos/                 Cifras de equilibrio (JSON). Se ajustan sin tocar código.
  reglas.json          Reglas globales: recursos, vidas, tiempo, estrellas, mazo, carril.
  unidades.json        Arquetipos del jugador.
  enemigos.json        Tipos de enemigo.
  poderes.json         Poderes de combate.
  misiones/            Una misión por archivo: ritmo de aparición y horda final.
textos/es.json         Todo texto que ve el jugador, por clave.
escenas/batalla/       Escena de la batalla.
scripts/autoload/      Datos y Textos (cargados al arrancar).
scripts/batalla/       Lógica: Batalla, Base, Obstaculo, Unidad, Enemigo, recursos, poder.
scripts/ui/            Interfaz: HUD, botones del mazo, pantalla de fin.
tests/                 Prueba de equilibrio sin pantalla.
docs/glosario.md       Nombres neutrales y su clave de texto.
arte/, sonido/         Vacías por ahora.
```

Reglas del código:

- Los nombres del código son los **neutrales del glosario** (`Base`, `Obstaculo`, `RecursoDespliegue`, `RecursoCombate`, `Unidad`, `Enemigo`, `PoderCombate`).
- Ningún texto visible va escrito en el código: se pide con `Textos.t("clave")`.
- Ninguna cifra de equilibrio va en el código: se lee de `datos/` con `Datos`.

## Prueba de equilibrio

Juega la misión sola con varias estrategias y comprueba el criterio del plan (solo con luchadores baratos se gana, pero no con 3 estrellas):

```
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/prueba_equilibrio.tscn
```

Corre también en GitHub Actions con cada push.

## Exportar a móvil

Al crear el preset de Android o iOS, en *Recursos → Filtros para exportar archivos que no son recursos* añade `datos/*.json, datos/misiones/*.json, textos/*.json`, porque Godot no incluye los JSON por defecto.
