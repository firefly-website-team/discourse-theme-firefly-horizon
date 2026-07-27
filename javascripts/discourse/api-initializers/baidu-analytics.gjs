import { apiInitializer } from "discourse/lib/api";

const BAIDU_ANALYTICS_QUEUE = "_hmt";

/**
 * 向百度统计上报 Discourse 单页应用的虚拟页面浏览。
 * 参数：
 * - url: 当前页面的路由地址。
 */
function trackBaiduPageView(url) {
  window[BAIDU_ANALYTICS_QUEUE].push(["_trackPageview", url]);
}

export default apiInitializer((api) => {
  api.onPageChange((url) => trackBaiduPageView(url));
});
