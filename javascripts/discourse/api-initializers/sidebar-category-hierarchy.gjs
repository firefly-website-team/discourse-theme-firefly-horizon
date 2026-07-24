import { apiInitializer } from "discourse/lib/api";
import { canDisplayCategory } from "discourse/lib/sidebar/helpers";
import Category from "discourse/models/category";

const CATEGORY_COMPONENTS = [
  "component:sidebar/user/categories-section",
  "component:sidebar/anonymous/categories-section",
];

/**
 * 返回当前侧栏配置应展示的树形类别列表。
 *
 * 父类别被选中时会带出其后代；只选中子类别时只补齐祖先，避免把未配置的
 * 兄弟类别一并加入侧栏。
 *
 * @param {object} component - Discourse 类别侧栏组件实例。
 * @returns {Category[]} 按父子顺序排列且经过权限过滤的类别。
 */
export function sidebarCategoryTree(component) {
  let allCategories = [...component.site.categories];

  if (!component.siteSettings.fixed_category_positions) {
    allCategories.sort((a, b) => a.name.localeCompare(b.name));
  }

  const categoryById = new Map(
    allCategories.map((category) => [category.id, category])
  );
  const selectedCategories = component.categories ?? [];
  const includedCategoryIds = new Set();

  const includeAncestors = (category) => {
    let currentCategory = category;

    while (currentCategory) {
      includedCategoryIds.add(currentCategory.id);
      currentCategory = categoryById.get(currentCategory.parent_category_id);
    }
  };

  const includeDescendants = (categoryId) => {
    allCategories.forEach((category) => {
      if (category.parent_category_id === categoryId) {
        includedCategoryIds.add(category.id);
        includeDescendants(category.id);
      }
    });
  };

  selectedCategories.forEach((category) => {
    includeAncestors(category);

    if (!category.parent_category_id) {
      includeDescendants(category.id);
    }
  });

  return Category.sortCategories(allCategories).filter((category) => {
    return (
      includedCategoryIds.has(category.id) &&
      canDisplayCategory(category.id, component.siteSettings)
    );
  });
}

function categoryDepth(category, categoryById) {
  let depth = 0;
  let parentId = category.parent_category_id;

  while (parentId && depth < 3) {
    depth += 1;
    parentId = categoryById.get(parentId)?.parent_category_id;
  }

  return depth;
}

function categoryIdFromModel(model) {
  if (typeof model !== "string") {
    return;
  }

  const categoryId = Number.parseInt(model.split("/").at(-1), 10);
  return Number.isNaN(categoryId) ? undefined : categoryId;
}

export default apiInitializer((api) => {
  const site = api.container.lookup("service:site");
  const categoryById = new Map(
    site.categories.map((category) => [category.id, category])
  );

  CATEGORY_COMPONENTS.forEach((componentName) => {
    api.modifyClass(
      componentName,
      (Superclass) =>
        class extends Superclass {
          get sortedCategories() {
            return sidebarCategoryTree(this);
          }
        }
    );
  });

  api.modifyClass(
    "component:sidebar/section-link",
    (Superclass) =>
      class extends Superclass {
        get wrapperClass() {
          const baseClass = super.wrapperClass;
          const category = categoryById.get(
            categoryIdFromModel(this.args.model)
          );

          if (!category) {
            return baseClass;
          }

          const depth = categoryDepth(category, categoryById);

          return `${baseClass} firefly-sidebar-category firefly-sidebar-category--depth-${depth}`;
        }
      }
  );

  site.categories.forEach((category) => {
    if (category.parent_category_id && category.styleType === "square") {
      api.registerCustomCategorySectionLinkPrefix({
        categoryId: category.id,
        prefixType: "square",
        prefixValue: [category.color],
        prefixColor: category.color,
      });
    }
  });
});
