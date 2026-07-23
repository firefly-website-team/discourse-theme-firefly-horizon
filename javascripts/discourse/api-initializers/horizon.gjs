import { apiInitializer } from "discourse/lib/api";
import I18n, { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import ExperimentalScreen from "../components/experimental-screen";
import FireflyBackgroundContainer from "../components/firefly-background-container";
import FireflyHeaderLinks from "../components/firefly-header-links";
import FireflyHeaderSearch from "../components/firefly-header-search";
import FireflyLanguageSwitcher from "../components/firefly-language-switcher";
import FireflyMobileSidebarToggle from "../components/firefly-mobile-sidebar-toggle";
import UserColorPaletteSelector from "../components/user-color-palette-selector";

const WELCOME_TITLE_FALLBACK = "欢迎访问Firefly论坛";
const WELCOME_SUBTITLE_FALLBACK =
  "很高兴在这里见到您。如果您需要帮助，请先搜索，然后再发帖。";

/**
 * 读取 Firefly 欢迎区主题文案。
 * 参数：
 * - key: 主题 locale 键名后缀。
 * - defaultValue: locale 缺失时使用的兜底文案。
 */
function fireflyWelcomeText(key, defaultValue) {
  return i18n(themePrefix(`firefly_welcome_banner.${key}`), {
    defaultValue,
  });
}

/**
 * 返回欢迎区标题。
 * 参数：无。
 */
function fireflyWelcomeTitle() {
  return fireflyWelcomeText("title", WELCOME_TITLE_FALLBACK);
}

/**
 * 返回欢迎区副标题。
 * 参数：无。
 */
function fireflyWelcomeSubtitle() {
  return fireflyWelcomeText("subtitle", WELCOME_SUBTITLE_FALLBACK);
}

/**
 * 覆盖 Discourse 欢迎区核心翻译。
 * 参数：无，直接写入当前 locale 的 js 翻译缓存。
 */
function applyFireflyWelcomeBannerTranslations() {
  const jsTranslations = I18n.translations?.[I18n.locale]?.js;

  if (!jsTranslations) {
    return;
  }

  jsTranslations.welcome_banner ??= {};
  jsTranslations.welcome_banner.header ??= {};
  jsTranslations.welcome_banner.subheader ??= {};

  const title = fireflyWelcomeTitle();
  const subtitle = fireflyWelcomeSubtitle();

  Object.assign(jsTranslations.welcome_banner.header, {
    anonymous_members: title,
    logged_in_members: title,
    new_members: title,
  });

  Object.assign(jsTranslations.welcome_banner.subheader, {
    anonymous_members: subtitle,
    logged_in_members: subtitle,
    new_members: subtitle,
  });
}

/**
 * 刷新已渲染的欢迎区 DOM 文案。
 * 参数：无，用于处理 SPA 切换后核心组件先于主题翻译渲染的场景。
 */
function refreshRenderedWelcomeBannerContent() {
  const title = fireflyWelcomeTitle();
  const subtitle = fireflyWelcomeSubtitle();

  document.querySelectorAll(".welcome-banner__title").forEach((element) => {
    let subheader = element.querySelector(".welcome-banner__subheader");

    Array.from(element.childNodes).forEach((node) => {
      if (node !== subheader) {
        node.remove();
      }
    });

    element.prepend(document.createTextNode(title));

    if (subtitle) {
      subheader ??= document.createElement("p");
      subheader.className = "welcome-banner__subheader";
      subheader.textContent = subtitle;
      element.appendChild(subheader);
    } else {
      subheader?.remove();
    }
  });
}

export default apiInitializer((api) => {
  applyFireflyWelcomeBannerTranslations();

  api.renderInOutlet("above-site-header", FireflyBackgroundContainer);
  api.renderInOutlet("header-contents__before", FireflyMobileSidebarToggle);
  api.renderInOutlet("above-main-container", ExperimentalScreen);
  api.headerIcons.delete("language-switcher");
  api.headerIcons.add("firefly-language-switcher", FireflyLanguageSwitcher, {
    before: "search",
  });
  api.headerIcons.add("firefly-header-links", FireflyHeaderLinks, {
    before: "firefly-language-switcher",
  });
  api.headerIcons.add("firefly-header-search", FireflyHeaderSearch, {
    after: "firefly-language-switcher",
    before: "interface-color-selector",
  });
  api.renderInOutlet("sidebar-footer-actions", UserColorPaletteSelector);

  api.onPageChange(() => {
    applyFireflyWelcomeBannerTranslations();
    requestAnimationFrame(refreshRenderedWelcomeBannerContent);
  });
});
