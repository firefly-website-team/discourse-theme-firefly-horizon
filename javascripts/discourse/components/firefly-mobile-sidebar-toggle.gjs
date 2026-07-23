import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class FireflyMobileSidebarToggle extends Component {
  @service navigationMenu;
  @service site;

  /**
   * 判断是否渲染移动端左侧菜单按钮。
   *
   * @returns {boolean} 当前视口为移动端且存在菜单切换回调时返回 true。
   */
  get shouldRender() {
    return this.site.mobileView && this.args.outletArgs?.toggleNavigationMenu;
  }

  /**
   * 返回菜单按钮图标。
   *
   * @returns {string} 核心页眉传入的图标名，缺省使用 bars。
   */
  get icon() {
    return this.args.outletArgs?.sidebarIcon || "bars";
  }

  /**
   * 切换移动端菜单显示状态。
   *
   * @param {MouseEvent} event - 点击菜单按钮时产生的浏览器事件。
   */
  @action
  toggle(event) {
    event.preventDefault();

    if (this.navigationMenu.isDesktopDropdownMode) {
      this.args.outletArgs.toggleNavigationMenu("hamburger");
    } else {
      this.args.outletArgs.toggleNavigationMenu();
    }
  }

  <template>
    {{#if this.shouldRender}}
      <span class="header-sidebar-toggle firefly-mobile-sidebar-toggle">
        <button
          title={{i18n "sidebar.title"}}
          class="btn btn-flat btn-sidebar-toggle no-text btn-icon"
          aria-expanded={{if @outletArgs.showSidebar "true" "false"}}
          aria-controls="d-sidebar"
          {{on "click" this.toggle}}
        >
          {{dIcon this.icon}}
        </button>
      </span>
    {{/if}}
  </template>
}
