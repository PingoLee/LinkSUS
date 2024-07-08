# Optional flat/non-resource MVC folder structure
# Genie.Loader.autoload(abspath("models"))
LinkSUS.Loader.autoload(
  abspath("models", "importadores.jl"), 
  abspath("models", "linkage_f.jl"), 
  abspath("models", "relatorio.jl"), 
  abspath("models", "Pag_ini.jl"),
  abspath("models", "Pag_config.jl"),
  abspath("models", "Pag_config_rel.jl")
)

# LinkSUS.Loader.@using "models/importadores"
# LinkSUS.Loader.@using "models/linkage_f"
# LinkSUS.Loader.@using "models/relatorio"
# LinkSUS.Loader.@using "models/Pag_ini"
# LinkSUS.Loader.@using "models/Pag_config"
# LinkSUS.Loader.@using "models/Pag_config_rel"

import LinkSUS.Genie.Renderer.Html: normal_element, register_normal_element
register_normal_element("q__drawer")
register_normal_element("q__layout")
register_normal_element("q__header")
register_normal_element("q__toolbar")
register_normal_element("q__btn")
register_normal_element("q__toolbar__title")
register_normal_element("q__list")
register_normal_element("q__item__label")
register_normal_element("q__page__container")
register_normal_element("q__space")
register_normal_element("q__item")
register_normal_element("q__item__section")
register_normal_element("q__icon")
register_normal_element("q__form")
register_normal_element("q__card")
register_normal_element("q__card__section")
register_normal_element("q__file")
register_normal_element("q__input")
register_normal_element("q__select")
register_normal_element(:q__btn__dropdown)
register_normal_element(:q__btn__dropdown__item)
register_normal_element(:q__tooltip)
register_normal_element(:q__badge)
register_normal_element(:q__slider)
register_normal_element(:q__dialog)
register_normal_element(:q__card__actions)
register_normal_element(:q__avatar)
register_normal_element(:q__table)
register_normal_element(:q__td)
register_normal_element(:q__toggle)
register_normal_element(:q__separator)
register_normal_element(:q__banner)
