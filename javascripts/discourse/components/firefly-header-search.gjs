import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";

const SEARCH_BUTTON_ID = "search-button";

export default class FireflyHeaderSearch extends Component {
  @service search;
  @service site;

  /**
   * 切换页眉全局搜索面板。
   * 参数：
   * - event: 点击搜索按钮时产生的浏览器事件。
   */
  @action
  toggleSearch(event) {
    event.preventDefault();

    this.search.visible = !this.search.visible;

    if (!this.search.visible) {
      this.resetSearchState();
      document.getElementById(SEARCH_BUTTON_ID)?.focus();
    }

    event.target.closest("button")?.blur();
  }

  /**
   * 重置搜索菜单的上下文状态。
   * 参数：无，直接清理 search service 中的临时状态。
   */
  resetSearchState() {
    this.search.highlightTerm = "";
    this.search.inTopicContext = false;
  }

  /**
   * 注册移动端点击空白处关闭搜索框的监听。
   * 参数：无，在 document 捕获阶段监听 pointerdown。
   */
  @action
  setupMobileOutsideClose() {
    document.addEventListener("pointerdown", this.closeOnOutsidePointerDown, {
      capture: true,
    });
  }

  /**
   * 移除移动端点击空白处关闭搜索框的监听。
   * 参数：无，用于组件销毁时清理 document 监听。
   */
  @action
  teardownMobileOutsideClose() {
    document.removeEventListener(
      "pointerdown",
      this.closeOnOutsidePointerDown,
      { capture: true }
    );
  }

  /**
   * 点击搜索框与搜索按钮以外区域时关闭移动端搜索框。
   *
   * @param {PointerEvent} event - document pointerdown 事件。
   */
  @action
  closeOnOutsidePointerDown(event) {
    if (!this.site.mobileView || !this.search.visible) {
      return;
    }

    if (event.target.closest(".search-menu-panel, .search-dropdown")) {
      return;
    }

    this.search.visible = false;
    this.resetSearchState();
    event.stopImmediatePropagation();
  }

  <template>
    <li
      class={{dConcatClass
        (if this.search.visible "active")
        "header-dropdown-toggle firefly-header-search search-dropdown"
      }}
      {{didInsert this.setupMobileOutsideClose}}
      {{willDestroy this.teardownMobileOutsideClose}}
    >
      <DButton
        class="icon btn-flat"
        aria-expanded={{this.search.visible}}
        aria-haspopup="true"
        aria-label={{i18n "search.title"}}
        id={{SEARCH_BUTTON_ID}}
        @icon="magnifying-glass"
        @translatedTitle={{i18n "search.title"}}
        {{on "click" this.toggleSearch}}
      />
    </li>
  </template>
}
