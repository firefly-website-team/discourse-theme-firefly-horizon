import { find, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import Topic from "discourse/models/topic";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { fakeTime } from "discourse/tests/helpers/qunit-helpers";
import HighContextTopicCard from "../../discourse/components/card/high-context-topic-card";

function topicFor(attrs = {}) {
  return Topic.create({
    id: 1,
    title: "How do cards work?",
    fancy_title: "How do cards work?",
    created_at: "2024-06-01T08:00:00Z",
    bumped_at: "2024-06-01T18:00:00Z",
    last_posted_at: "2024-06-01T12:00:00Z",
    last_poster_username: "alice",
    posts_count: 3,
    like_count: 0,
    tags: [],
    posters: [
      {
        extras: "latest single",
        user: {
          id: 1,
          username: "alice",
          name: "Alice",
          avatar_template: "/letter_avatar_proxy/v4/letter/a/{size}.png",
        },
      },
    ],
    ...attrs,
  });
}

module(
  "Horizon | Integration | Component | Card | HighContextTopicCard",
  function (hooks) {
    setupRenderingTest(hooks);

    let clock;

    hooks.beforeEach(function () {
      clock = fakeTime("2024-06-01T13:04:00Z", null, true);
    });

    hooks.afterEach(function () {
      clock?.restore();
    });

    test("shows the actual reply time when a reply is recent", async function (assert) {
      const lastPostedAt = "2024-06-01T12:00:00Z";
      const topic = topicFor({
        bumped_at: "2024-06-01T18:00:00Z",
        last_posted_at: lastPostedAt,
      });

      await render(
        <template>
          <HighContextTopicCard @topic={{topic}} @hideCategory={{true}} />
        </template>
      );

      assert.dom(".hc-topic-card__time .relative-date").exists();
      assert
        .dom(".hc-topic-card__time .relative-date")
        .hasAttribute("data-time", String(new Date(lastPostedAt).getTime()));
    });

    test("uses Discourse's relative-date thresholds for recent replies", async function (assert) {
      const topic = topicFor({
        last_posted_at: "2024-06-01T12:00:00Z",
      });

      await render(
        <template>
          <HighContextTopicCard @topic={{topic}} @hideCategory={{true}} />
        </template>
      );

      assert.ok(
        /^(1h ago|1 小时前)$/.test(
          find(".hc-topic-card__time .relative-date").textContent.trim()
        )
      );
    });

    test("hides the reply time when the topic was bumped more than a day after the last post", async function (assert) {
      const topic = topicFor({
        bumped_at: "2024-06-10T12:00:00Z",
        last_posted_at: "2024-06-01T12:00:00Z",
      });

      await render(
        <template>
          <HighContextTopicCard @topic={{topic}} @hideCategory={{true}} />
        </template>
      );

      assert.dom(".hc-topic-card__time .relative-date").doesNotExist();
    });
  }
);
