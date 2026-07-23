import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DMenu from "discourse/float-kit/components/d-menu";
import { ajax } from "discourse/lib/ajax";
import cookie, { removeCookie } from "discourse/lib/cookie";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import I18n, { i18n } from "discourse-i18n";

const SHOW_ORIGINAL_COOKIE = "content-localization-show-original";

export default class FireflyLanguageSwitcher extends Component {
  @service siteSettings;
  @service languageNameLookup;
  @service currentUser;

  /**
   * 判断页眉语言切换器是否应该显示。
   *
   * @returns {boolean} 站点启用内容本地化并满足后台显示范围设置时返回 true。
   */
  get shouldRender() {
    if (!this.siteSettings.content_localization_enabled) {
      return false;
    }

    const hasLocales =
      !!this.siteSettings.content_localization_supported_locales;

    switch (this.siteSettings.content_localization_language_switcher) {
      case "anonymous":
        return !this.currentUser && hasLocales;
      case "all":
        return hasLocales;
      default:
        return false;
    }
  }

  /**
   * 返回当前 Discourse 界面语言。
   *
   * @returns {string} 当前 I18n locale，例如 zh_CN 或 en。
   */
  get currentLocale() {
    return I18n.locale;
  }

  /**
   * 返回当前语言的完整显示名称。
   *
   * @returns {string} 当前语言名称，例如 简体中文 或 English。
   */
  get currentLanguageName() {
    return this.languageName(this.currentLocale);
  }

  /**
   * 返回下拉菜单内可切换语言的显示数据。
   *
   * @returns {Array<{name: string, value: string, isActive: boolean}>} 语言选项列表。
   */
  get content() {
    const langs = this.siteSettings.available_content_localization_locales.map(
      ({ value }) => ({
        name: this.languageName(value),
        value,
        isActive: value === this.currentLocale,
      })
    );

    if (!langs.some(({ value }) => value === "en")) {
      const ukLang = langs.find((lang) => lang.value === "en_GB");

      if (ukLang) {
        ukLang.name = this.normalizeUKEnglish(ukLang.name);
      }
    }

    if (!langs.some(({ value }) => value === "pt")) {
      const ptbrLang = langs.find((lang) => lang.value === "pt_BR");

      if (ptbrLang) {
        ptbrLang.name = this.normalizeBRPortuguese(ptbrLang.name);
      }
    }

    return langs;
  }

  /**
   * 读取指定 locale 的完整语言名称。
   *
   * @param {string} locale - 语言代码，例如 zh_CN 或 en。
   * @returns {string} Discourse 后台语言列表使用的显示名称。
   */
  languageName(locale) {
    return this.languageNameLookup.getLanguageName(locale);
  }

  /**
   * 规范化英国英语只有单一英文变体时的显示名称。
   *
   * @param {string} text - 待处理的语言名称。
   * @returns {string} 规范化后的语言名称。
   */
  normalizeUKEnglish(text) {
    let result = text.replace("(English (UK))", "");
    result = result
      .replace(/\s*\([^)]*\)/g, "")
      .replace(/\s+/g, " ")
      .trim();

    if (text.includes("English") && !result.match(/^English/i)) {
      result += " (English)";
    }

    return result;
  }

  /**
   * 规范化巴西葡萄牙语只有单一葡语变体时的显示名称。
   *
   * @param {string} text - 待处理的语言名称。
   * @returns {string} 规范化后的语言名称。
   */
  normalizeBRPortuguese(text) {
    let result = text.replace("(Português (BR))", "");
    result = result
      .replace(/\s*\([^)]*\)/g, "")
      .replace(/\s+/g, " ")
      .trim();

    if (text.includes("Português") && !result.match(/^Português/i)) {
      result += " (Português)";
    }

    return result;
  }

  /**
   * 切换当前用户或访客的界面语言。
   *
   * @param {string} locale - 要切换到的语言代码。
   */
  @action
  async changeLocale(locale) {
    if (this.currentUser) {
      this.currentUser.set("locale", locale);
      this.currentUser.set("user_option.show_original_content", false);

      await ajax(`/u/${this.currentUser.username}.json`, {
        type: "PUT",
        data: { locale, show_original_content: false },
      });
    } else {
      cookie("locale", locale, { path: "/" });
    }

    removeCookie(SHOW_ORIGINAL_COOKIE, { path: "/" });

    this.dMenu.close();
    window.location.reload();
  }

  /**
   * 保存 DMenu API，便于切换语言后关闭菜单。
   *
   * @param {object} api - DMenu 注册回调提供的菜单 API。
   */
  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  <template>
    {{#if this.shouldRender}}
      <DMenu
        @identifier="language-switcher"
        @title={{i18n "language_switcher.title"}}
        class="btn-flat firefly-language-switcher"
        @onRegisterApi={{this.onRegisterApi}}
      >
        <:trigger>
          <span
            class="language-switcher__locale firefly-language-switcher__locale"
          >
            {{this.currentLanguageName}}
          </span>
          {{dIcon "angle-down"}}
        </:trigger>
        <:content>
          <DDropdownMenu as |dropdown|>
            {{#each this.content as |option|}}
              <dropdown.item
                class="locale-options {{if option.isActive '--selected'}}"
                data-menu-option-id={{option.value}}
              >
                <DButton
                  @translatedLabel={{option.name}}
                  @action={{fn this.changeLocale option.value}}
                />
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
