import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

export default class FireflyHeaderLinks extends Component {
  @service header;
  @service currentUser;

  /**
   * 控制顶部链接是否渲染。
   * 参数：无，读取 header service 中的话题标题浮动状态。
   */
  get shouldRender() {
    return !this.header.topicInfoVisible;
  }

  /**
   * 返回文档入口地址。
   * 参数：无，读取主题设置 firefly_docs_url。
   */
  get docsUrl() {
    return settings.firefly_docs_url || "/docs";
  }

  /**
   * 返回社区入口地址。
   * 参数：无，读取主题设置 firefly_community_url。
   */
  get communityUrl() {
    return settings.firefly_community_url || "/";
  }

  /**
   * 在页眉 DOM 渲染完成后调整顶部导航位置。
   *
   * @param {HTMLElement} element - 组件根节点。
   */
  @action
  positionHeaderLinks(element) {
    requestAnimationFrame(() => this.applyHeaderLinksPosition(element));
  }

  /**
   * 根据登录状态把顶部导航放到设计稿对应的位置。
   *
   * @param {HTMLElement} element - 组件根节点。
   */
  applyHeaderLinksPosition(element) {
    const panel = element.closest(".panel");
    const icons = panel?.querySelector(".d-header-icons");
    const headerButtons = panel?.querySelector(".header-buttons");
    const authButtons = headerButtons?.querySelector(".auth-buttons");

    if (!panel || !icons) {
      return;
    }

    if (!this.currentUser && headerButtons && authButtons) {
      if (
        element.parentElement !== panel ||
        element.nextElementSibling !== headerButtons
      ) {
        panel.insertBefore(element, headerButtons);
      }

      return;
    }

    const languageSwitcher = icons.querySelector(".firefly-language-switcher");

    if (element.parentElement !== icons) {
      icons.insertBefore(element, languageSwitcher ?? icons.firstChild);
    } else if (
      languageSwitcher &&
      element.nextElementSibling !== languageSwitcher
    ) {
      icons.insertBefore(element, languageSwitcher);
    }
  }

  <template>
    {{#if this.shouldRender}}
      <div
        class="firefly-header-links-item"
        {{didInsert this.positionHeaderLinks}}
        {{didUpdate this.positionHeaderLinks this.currentUser}}
      >
        <nav
          class="firefly-header-links"
          aria-label={{i18n (themePrefix "header_links.aria_label")}}
        >
          <a class="firefly-header-links__item" href={{this.docsUrl}}>
            {{i18n (themePrefix "header_links.docs")}}
          </a>
          <a class="firefly-header-links__item" href={{this.communityUrl}}>
            {{i18n (themePrefix "header_links.community")}}
          </a>
        </nav>
      </div>
    {{/if}}
  </template>
}
