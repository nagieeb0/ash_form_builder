defmodule AshFormBuilder.Themes.Default do
  @moduledoc """
  Default theme for AshFormBuilder — a modern, polished Tailwind-based
  look that's production-ready out of the box. Heavily inspired by the
  best contemporary form designs (Linear, Vercel, Stripe).

  Reads `:accent` and `:transitions` from `theme_opts` so per-form DSL
  settings are honored without modifying the theme.

  ## Highlights

  * iOS-style toggles, segmented date pickers, chip-style multi-select
  * Searchable + creatable multi-select combobox for many-to-many
  * Generous tap targets and full responsiveness on small screens
  * Soft, layered focus rings using the accent color
  * First-class dark mode and pluggable accent color
  """

  @behaviour AshFormBuilder.Theme

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    accent = Keyword.get(opts, :accent, :indigo)
    transitions = Keyword.get(opts, :transitions, :subtle)
    target = Keyword.get(opts, :target)

    assigns =
      assigns
      |> Map.put(:accent, accent)
      |> Map.put(:transitions, transitions)
      |> Map.put(:component_target, target)
      |> Map.put(:theme_opts, opts)

    case assigns.field.type do
      :hidden -> render_hidden(assigns)
      :file_upload -> render_file_upload(assigns)
      :checkbox -> render_checkbox(assigns)
      :toggle -> render_toggle(assigns)
      :checkbox_group -> render_checkbox_group(assigns)
      :textarea -> render_textarea(assigns)
      :select -> render_select_or_chips(assigns)
      :multiselect_combobox -> render_multiselect(assigns)
      :number -> render_number_stepper(assigns)
      type when type in [:date, :datetime] -> render_date_like(assigns)
      _ -> render_text_like(assigns)
    end
  end

  defp render_select_or_chips(assigns) do
    options = normalize_options(assigns.field.options)

    cond do
      length(options) > 0 and length(options) <= 4 ->
        render_segmented(Map.put(assigns, :options, options))

      true ->
        render_select(assigns)
    end
  end

  @impl AshFormBuilder.Theme
  def render_nested(_assigns), do: nil

  # ---------------------------------------------------------------------------
  # Field renderers — text-like family
  # ---------------------------------------------------------------------------

  defp render_hidden(assigns) do
    ~H"""
    <input
      type="hidden"
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
    />
    """
  end

  defp render_text_like(assigns) do
    has_affix? = !is_nil(assigns.field.prefix) || !is_nil(assigns.field.suffix)
    assigns = Map.put(assigns, :has_affix?, has_affix?)

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <%= if @has_affix? do %>
        <div class="relative">
          <span
            :if={@field.prefix}
            class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-sm font-medium text-gray-400 dark:text-gray-500 select-none"
          >
            {@field.prefix}
          </span>
          <input
            type={html_input_type(@field.type)}
            id={Phoenix.HTML.Form.input_id(@form, @field.name)}
            name={Phoenix.HTML.Form.input_name(@form, @field.name)}
            value={Phoenix.HTML.Form.input_value(@form, @field.name)}
            placeholder={@field.placeholder}
            required={@field.required}
            autocomplete={@field.autocomplete}
            autofocus={@field.autofocus}
            readonly={@field.readonly}
            disabled={@field.disabled}
            min={@field.min}
            max={@field.max}
            step={@field.step}
            pattern={@field.pattern}
            maxlength={@field.maxlength}
            inputmode={@field.inputmode}
            class={[
              input_classes(@accent, @transitions, has_visible_error?(assigns)),
              @field.prefix && "pl-8",
              @field.suffix && "pr-12",
              @field.class
            ]}
            phx-debounce="300"
          />
          <span
            :if={@field.suffix}
            class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-sm font-medium text-gray-400 dark:text-gray-500 select-none"
          >
            {@field.suffix}
          </span>
        </div>
      <% else %>
        <input
          type={html_input_type(@field.type)}
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value={Phoenix.HTML.Form.input_value(@form, @field.name)}
          placeholder={@field.placeholder}
          required={@field.required}
          autocomplete={@field.autocomplete}
          autofocus={@field.autofocus}
          readonly={@field.readonly}
          disabled={@field.disabled}
          min={@field.min}
          max={@field.max}
          step={@field.step}
          pattern={@field.pattern}
          maxlength={@field.maxlength}
          inputmode={@field.inputmode}
          class={[
            input_classes(@accent, @transitions, has_visible_error?(assigns)),
            @field.class
          ]}
          phx-debounce="300"
        />
      <% end %>
    </.field_wrapper>
    """
  end

  # ---------------------------------------------------------------------------
  # Date / datetime — iOS-style picker presentation
  # ---------------------------------------------------------------------------

  defp render_date_like(assigns) do
    icon =
      case assigns.field.type do
        :datetime -> :clock
        _ -> :calendar
      end

    assigns = Map.put(assigns, :icon, icon)

    field_id = Phoenix.HTML.Form.input_id(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_id, field_id)

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <div
        id={@field_id <> "_picker"}
        phx-hook=".AshFormDatePicker"
        phx-update="ignore"
        data-input-type={html_input_type(@field.type)}
        class={[
          "group relative flex items-stretch rounded-xl overflow-hidden cursor-pointer",
          "bg-white dark:bg-gray-900 ring-1 ring-inset shadow-sm",
          if(has_visible_error?(assigns),
            do: "ring-red-300 dark:ring-red-700",
            else: "ring-gray-200 dark:ring-gray-700"
          ),
          "focus-within:ring-2 focus-within:ring-#{@accent}-500",
          "active:scale-[0.997]",
          transition_classes(@transitions)
        ]}
      >
        <button
          type="button"
          data-part="trigger"
          class="flex flex-1 items-stretch text-left focus:outline-none"
          aria-haspopup="dialog"
        >
          <span class={[
            "flex items-center justify-center w-12 sm:w-11 shrink-0",
            "bg-#{@accent}-50/70 dark:bg-#{@accent}-950/30",
            "text-#{@accent}-600 dark:text-#{@accent}-400",
            "border-r border-gray-200 dark:border-gray-700"
          ]}>
            <.field_icon name={@icon} class="h-5 w-5" />
          </span>
          <span
            data-part="display"
            class={[
              "flex-1 flex items-center min-w-0",
              "px-3.5 py-3.5 text-base sm:py-2.5 sm:text-[15px] lg:text-sm",
              "text-gray-900 dark:text-gray-100 tabular-nums tracking-tight",
              "data-[empty=true]:text-gray-400 dark:data-[empty=true]:text-gray-500",
              @field.class
            ]}
            data-empty={
              if(Phoenix.HTML.Form.input_value(@form, @field.name) in [nil, ""],
                do: "true",
                else: "false"
              )
            }
          >
            {format_date_display(
              Phoenix.HTML.Form.input_value(@form, @field.name),
              @field.type,
              @field.placeholder
            )}
          </span>
          <span
            aria-hidden="true"
            class={[
              "flex items-center gap-1 pr-3.5 select-none",
              "text-[11px] font-medium uppercase tracking-wider",
              "text-gray-400 dark:text-gray-500",
              "group-hover:text-#{@accent}-600 dark:group-hover:text-#{@accent}-400",
              "transition-colors"
            ]}
          >
            <span class="hidden sm:inline">Choose</span>
            <svg
              class="h-3.5 w-3.5 transition-transform group-hover:translate-y-px"
              viewBox="0 0 20 20"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M5 8l5 5 5-5" />
            </svg>
          </span>
        </button>

        <input
          type="hidden"
          id={@field_id}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value={Phoenix.HTML.Form.input_value(@form, @field.name)}
          required={@field.required}
          data-part="value"
        />

        <dialog
          data-part="dialog"
          data-mode={if @field.type == :datetime, do: "datetime", else: "date"}
          class={[
            "fixed inset-0 m-auto p-0 rounded-2xl",
            "bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100",
            "shadow-2xl ring-1 ring-black/5 dark:ring-white/10",
            "w-[min(24rem,calc(100vw-2rem))] h-fit max-h-[90vh]",
            "backdrop:bg-gray-900/50 backdrop:backdrop-blur-sm",
            "open:animate-[fadeInScale_180ms_ease-out]"
          ]}
        >
          <div class="flex flex-col">
            <header class="flex items-center justify-between px-4 py-3 border-b border-gray-100 dark:border-gray-800">
              <button
                type="button"
                data-action="cancel"
                class="text-sm font-medium text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                Cancel
              </button>
              <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 select-none">
                {@field.label || "Select date"}
              </h3>
              <button
                type="button"
                data-action="apply"
                class={"text-sm font-semibold text-#{@accent}-600 hover:text-#{@accent}-700 dark:text-#{@accent}-400 dark:hover:text-#{@accent}-300 transition-colors"}
              >
                Confirm
              </button>
            </header>

            <div data-part="wheels" class="relative h-[220px] select-none">
              <div
                aria-hidden="true"
                class={"pointer-events-none absolute inset-x-3 top-1/2 -translate-y-1/2 h-10 border-y border-#{@accent}-100 dark:border-#{@accent}-900/40 bg-#{@accent}-50/30 dark:bg-#{@accent}-950/20 rounded-md z-10"}
              >
              </div>

              <div class={[
                "grid h-full px-3",
                if(@field.type == :datetime, do: "grid-cols-5", else: "grid-cols-3")
              ]}>
                <ul
                  data-part="col"
                  data-axis="month"
                  class={wheel_col_classes()}
                >
                  <li class="h-[90px]" aria-hidden="true"></li>
                  <li :for={n <- 1..12} data-value={n} class={wheel_item_classes()}>
                    {month_short(n)}
                  </li>
                  <li class="h-[90px]" aria-hidden="true"></li>
                </ul>
                <ul data-part="col" data-axis="day" class={wheel_col_classes()}>
                  <li class="h-[90px]" aria-hidden="true"></li>
                  <li :for={n <- 1..31} data-value={n} class={wheel_item_classes()}>
                    {n}
                  </li>
                  <li class="h-[90px]" aria-hidden="true"></li>
                </ul>
                <ul data-part="col" data-axis="year" class={wheel_col_classes()}>
                  <li class="h-[90px]" aria-hidden="true"></li>
                  <li :for={n <- year_range()} data-value={n} class={wheel_item_classes()}>
                    {n}
                  </li>
                  <li class="h-[90px]" aria-hidden="true"></li>
                </ul>
                <%= if @field.type == :datetime do %>
                  <ul data-part="col" data-axis="hour" class={wheel_col_classes()}>
                    <li class="h-[90px]" aria-hidden="true"></li>
                    <li :for={n <- 0..23} data-value={n} class={wheel_item_classes()}>
                      {String.pad_leading(to_string(n), 2, "0")}
                    </li>
                    <li class="h-[90px]" aria-hidden="true"></li>
                  </ul>
                  <ul data-part="col" data-axis="minute" class={wheel_col_classes()}>
                    <li class="h-[90px]" aria-hidden="true"></li>
                    <li :for={n <- 0..59} data-value={n} class={wheel_item_classes()}>
                      {String.pad_leading(to_string(n), 2, "0")}
                    </li>
                    <li class="h-[90px]" aria-hidden="true"></li>
                  </ul>
                <% end %>
              </div>
            </div>

            <footer class="flex items-center justify-center px-4 py-2 border-t border-gray-100 dark:border-gray-800 bg-gray-50/60 dark:bg-gray-950/40 rounded-b-2xl">
              <button
                type="button"
                data-action="clear"
                class="text-xs font-medium text-gray-500 hover:text-red-600 dark:text-gray-400 dark:hover:text-red-400 transition-colors"
              >
                Clear
              </button>
            </footer>
          </div>
        </dialog>
      </div>
      <style>
        @keyframes fadeInScale {
          from { opacity: 0; transform: scale(0.96) translateY(4px); }
          to   { opacity: 1; transform: scale(1) translateY(0); }
        }
      </style>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".AshFormDatePicker" runtime>
        {
          mounted() {
            this.ITEM_H = 40;
            this.trigger = this.el.querySelector('[data-part="trigger"]');
            this.display = this.el.querySelector('[data-part="display"]');
            this.valueInput = this.el.querySelector('[data-part="value"]');
            this.dialog = this.el.querySelector('[data-part="dialog"]');
            this.applyBtn = this.dialog.querySelector('[data-action="apply"]');
            this.cancelBtn = this.dialog.querySelector('[data-action="cancel"]');
            this.clearBtn = this.dialog.querySelector('[data-action="clear"]');
            this.mode = this.dialog.dataset.mode || "date";
            this.inputType = this.el.dataset.inputType || "date";
            this.placeholder = this.mode === "datetime" ? "Pick date & time" : "Pick a date";

            this.cols = {};
            this.dialog.querySelectorAll('[data-part="col"]').forEach(col => {
              this.cols[col.dataset.axis] = col;
            });

            // Reactive day-count: updates the day column when month/year change
            this.refreshDayBounds = () => {
              const m = this.readCol("month");
              const y = this.readCol("year");
              if (!m || !y) return;
              const last = new Date(y, m, 0).getDate(); // day 0 of next month
              const dayCol = this.cols.day;
              dayCol.querySelectorAll("li[data-value]").forEach(li => {
                const v = Number(li.dataset.value);
                li.classList.toggle("opacity-30", v > last);
                li.classList.toggle("pointer-events-none", v > last);
              });
              if (this.readCol("day") > last) this.scrollColTo("day", last, true);
            };

            this.formatRaw = () => {
              const y = this.readCol("year");
              const m = String(this.readCol("month")).padStart(2, "0");
              const d = String(Math.min(this.readCol("day"), new Date(y, this.readCol("month"), 0).getDate())).padStart(2, "0");
              if (this.mode === "datetime") {
                const h = String(this.readCol("hour")).padStart(2, "0");
                const mi = String(this.readCol("minute")).padStart(2, "0");
                return `${y}-${m}-${d}T${h}:${mi}`;
              }
              return `${y}-${m}-${d}`;
            };

            this.formatDisplay = (raw) => {
              if (!raw) return this.placeholder;
              try {
                const d = new Date(this.mode === "datetime" ? raw : raw + "T00:00");
                if (isNaN(d.getTime())) return raw;
                if (this.mode === "datetime") {
                  return d.toLocaleString(undefined, { weekday: "short", month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" });
                }
                return d.toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric", year: "numeric" });
              } catch (_) { return raw; }
            };

            this.applyValue = (raw) => {
              this.valueInput.value = raw || "";
              this.display.textContent = this.formatDisplay(raw);
              this.display.dataset.empty = raw ? "false" : "true";
              this.valueInput.dispatchEvent(new Event("input", { bubbles: true }));
              this.valueInput.dispatchEvent(new Event("change", { bubbles: true }));
            };

            this.parseInitial = () => {
              const today = new Date();
              const raw = this.valueInput.value;
              if (!raw) {
                return { y: today.getFullYear(), m: today.getMonth() + 1, d: today.getDate(), hh: 9, mi: 0 };
              }
              const [datePart, timePart] = raw.split("T");
              const [y, m, d] = datePart.split("-").map(Number);
              const [hh, mi] = (timePart || "09:00").split(":").map(Number);
              return { y, m, d, hh, mi };
            };

            this.scrollColTo = (axis, value, smooth = false) => {
              const col = this.cols[axis];
              if (!col) return;
              const target = col.querySelector(`li[data-value="${value}"]`);
              if (!target) return;
              const top = target.offsetTop - (col.clientHeight / 2 - this.ITEM_H / 2);
              col.scrollTo({ top, behavior: smooth ? "smooth" : "instant" });
            };

            this.readCol = (axis) => {
              const col = this.cols[axis];
              if (!col) return null;
              const active = col.querySelector('li[data-active="true"]');
              if (active) return Number(active.dataset.value);
              const idx = Math.round(col.scrollTop / this.ITEM_H);
              const items = col.querySelectorAll("li[data-value]");
              const item = items[Math.max(0, Math.min(idx, items.length - 1))];
              return item ? Number(item.dataset.value) : null;
            };

            this.markActive = (col) => {
              const cy = col.getBoundingClientRect().top + col.clientHeight / 2;
              let nearest = null;
              let nearestDist = Infinity;
              col.querySelectorAll("li[data-value]").forEach(li => {
                const r = li.getBoundingClientRect();
                const d = Math.abs(r.top + r.height / 2 - cy);
                li.dataset.active = "false";
                if (d < nearestDist) { nearestDist = d; nearest = li; }
              });
              if (nearest) nearest.dataset.active = "true";
            };

            this.openDialog = () => {
              if (typeof this.dialog.showModal !== "function") return;
              this.dialog.showModal();
              const init = this.parseInitial();
              requestAnimationFrame(() => {
                this.scrollColTo("month", init.m);
                this.scrollColTo("day", init.d);
                this.scrollColTo("year", init.y);
                if (this.mode === "datetime") {
                  this.scrollColTo("hour", init.hh);
                  this.scrollColTo("minute", init.mi);
                }
                Object.values(this.cols).forEach(c => this.markActive(c));
                this.refreshDayBounds();
              });
            };

            this.closeDialog = () => { if (this.dialog.open) this.dialog.close(); };

            // Wire up scroll snap → active highlight + day-bounds + click-to-snap.
            // Active marker updates are batched via rAF so we don't re-paint on
            // every scroll event (which causes flicker on momentum scroll).
            Object.values(this.cols).forEach(col => {
              let rafPending = false;
              let snapTimer;
              col.addEventListener("scroll", () => {
                if (!rafPending) {
                  rafPending = true;
                  requestAnimationFrame(() => {
                    this.markActive(col);
                    rafPending = false;
                  });
                }
                clearTimeout(snapTimer);
                snapTimer = setTimeout(() => {
                  this.markActive(col);
                  if (col.dataset.axis === "month" || col.dataset.axis === "year") {
                    this.refreshDayBounds();
                  }
                }, 120);
              });
              // Modern browsers fire `scrollend` after momentum settles — finalize.
              col.addEventListener("scrollend", () => {
                this.markActive(col);
                if (col.dataset.axis === "month" || col.dataset.axis === "year") {
                  this.refreshDayBounds();
                }
              });
              col.addEventListener("click", (e) => {
                const li = e.target.closest("li[data-value]");
                if (!li || li.classList.contains("pointer-events-none")) return;
                this.scrollColTo(col.dataset.axis, Number(li.dataset.value), true);
              });
              // Wheel on desktop — translate vertical wheel to a snap-step move.
              col.addEventListener("wheel", (e) => {
                if (Math.abs(e.deltaY) < 4) return;
                e.preventDefault();
                const dir = e.deltaY > 0 ? 1 : -1;
                const idx = Math.round(col.scrollTop / this.ITEM_H);
                const items = col.querySelectorAll("li[data-value]");
                const next = Math.max(0, Math.min(idx + dir, items.length - 1));
                col.scrollTo({ top: next * this.ITEM_H, behavior: "smooth" });
              }, { passive: false });
            });

            this.trigger.addEventListener("click", (e) => { e.preventDefault(); this.openDialog(); });
            this.applyBtn.addEventListener("click", () => {
              Object.values(this.cols).forEach(c => this.markActive(c));
              this.applyValue(this.formatRaw());
              this.closeDialog();
            });
            this.cancelBtn.addEventListener("click", () => this.closeDialog());
            this.clearBtn.addEventListener("click", () => { this.applyValue(""); this.closeDialog(); });

            // Close on backdrop click
            this.dialog.addEventListener("click", (e) => {
              const r = this.dialog.getBoundingClientRect();
              const inDialog = e.clientX >= r.left && e.clientX <= r.right &&
                               e.clientY >= r.top && e.clientY <= r.bottom;
              if (!inDialog) this.closeDialog();
            });
          },
          destroyed() {
            if (this.dialog && this.dialog.open) this.dialog.close();
          }
        }
      </script>
    </.field_wrapper>
    """
  end

  defp render_textarea(assigns) do
    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <textarea
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        placeholder={@field.placeholder}
        required={@field.required}
        rows={@field.rows || 4}
        autocomplete={@field.autocomplete}
        autofocus={@field.autofocus}
        readonly={@field.readonly}
        disabled={@field.disabled}
        maxlength={@field.maxlength}
        class={[
          input_classes(@accent, @transitions, has_visible_error?(assigns)),
          "leading-relaxed resize-y min-h-[6rem]",
          @field.class
        ]}
        phx-debounce="300"
      ><%= Phoenix.HTML.Form.normalize_value("textarea", Phoenix.HTML.Form.input_value(@form, @field.name)) %></textarea>
    </.field_wrapper>
    """
  end

  defp render_select(assigns) do
    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <div class="relative">
        <select
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          required={@field.required}
          autofocus={@field.autofocus}
          disabled={@field.disabled}
          class={[
            input_classes(@accent, @transitions, has_visible_error?(assigns)),
            "appearance-none pr-10",
            @field.class
          ]}
        >
          <option value="">{@field.placeholder || "— Select —"}</option>
          <option
            :for={{label, value} <- normalize_options(@field.options)}
            value={to_string(value)}
            selected={selected?(Phoenix.HTML.Form.input_value(@form, @field.name), value)}
          >
            {label}
          </option>
        </select>
        <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 dark:text-gray-500">
          <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path
              fill-rule="evenodd"
              d="M10 14l-5-5 1.4-1.4L10 11.2l3.6-3.6L15 9z"
              clip-rule="evenodd"
            />
          </svg>
        </span>
      </div>
    </.field_wrapper>
    """
  end

  # iOS-style segmented control / choice chips for small option lists
  defp render_segmented(assigns) do
    current = Phoenix.HTML.Form.input_value(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :current, current)

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <div class="flex flex-wrap gap-1.5 rounded-xl bg-gray-100 dark:bg-gray-800/70 p-1.5 w-full">
        <label
          :for={{label, value} <- @options}
          class={[
            "flex-1 min-w-[5rem] text-center cursor-pointer rounded-lg px-3.5 py-2 sm:py-2.5",
            "text-sm font-medium select-none whitespace-nowrap tracking-tight",
            if(selected?(@current, value),
              do:
                "bg-white text-#{@accent}-700 shadow-sm ring-1 ring-black/5 dark:bg-gray-900 dark:text-#{@accent}-300",
              else:
                "text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-white/40 dark:hover:bg-gray-900/40"
            ),
            transition_classes(@transitions)
          ]}
        >
          <input
            type="radio"
            name={Phoenix.HTML.Form.input_name(@form, @field.name)}
            value={to_string(value)}
            checked={selected?(@current, value)}
            class="sr-only"
          />
          {label}
        </label>
      </div>
    </.field_wrapper>
    """
  end

  # iOS-style number stepper with smooth value bump animation
  defp render_number_stepper(assigns) do
    raw_value = Phoenix.HTML.Form.input_value(assigns.form, assigns.field.name)
    value_str = if is_nil(raw_value), do: "", else: to_string(raw_value)
    field_id = Phoenix.HTML.Form.input_id(assigns.form, assigns.field.name)

    assigns =
      assigns
      |> Map.put(:value_str, value_str)
      |> Map.put(:field_id, field_id)

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <div
        id={@field_id <> "_stepper"}
        phx-hook=".AshFormStepper"
        phx-update="ignore"
        data-target-id={@field_id}
        data-min={@field.min}
        data-max={@field.max}
        data-step={@field.step || 1}
        class={[
          "flex items-stretch rounded-xl overflow-hidden",
          "bg-white dark:bg-gray-900 ring-1 ring-inset shadow-sm",
          if(has_visible_error?(assigns),
            do: "ring-red-300 dark:ring-red-700",
            else: "ring-gray-200 dark:ring-gray-700"
          ),
          "focus-within:ring-2 focus-within:ring-#{@accent}-500",
          transition_classes(@transitions)
        ]}
      >
        <button
          type="button"
          data-part="dec"
          aria-label="Decrease"
          class={[
            "w-12 sm:w-11 shrink-0 flex items-center justify-center text-2xl leading-none font-light",
            "text-gray-600 dark:text-gray-300 bg-gray-50 dark:bg-gray-800/60",
            "active:bg-#{@accent}-100 active:text-#{@accent}-700",
            "border-r border-gray-200 dark:border-gray-700",
            "transition-colors duration-150 ease-out select-none"
          ]}
        >
          <span
            data-glyph
            class="inline-block transition-transform duration-150 ease-out [button:active>&]:scale-90 [button:active>&]:translate-y-px"
          >
            −
          </span>
        </button>
        <input
          type="number"
          id={@field_id}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value={@value_str}
          placeholder={@field.placeholder}
          required={@field.required}
          autofocus={@field.autofocus}
          readonly={@field.readonly}
          disabled={@field.disabled}
          min={@field.min}
          max={@field.max}
          step={@field.step}
          inputmode="numeric"
          data-part="value"
          class={[
            "flex-1 min-w-0 border-0 bg-transparent text-center",
            "px-3 py-3 sm:py-2.5 text-base sm:text-sm font-medium tabular-nums",
            "text-gray-900 dark:text-gray-100",
            "placeholder:text-gray-400 dark:placeholder:text-gray-500",
            "focus:outline-none focus:ring-0",
            "[&::-webkit-inner-spin-button]:appearance-none",
            "[&::-webkit-outer-spin-button]:appearance-none",
            "[appearance:textfield]",
            @field.class
          ]}
          phx-debounce="300"
        />
        <button
          type="button"
          data-part="inc"
          aria-label="Increase"
          class={[
            "w-12 sm:w-11 shrink-0 flex items-center justify-center text-2xl leading-none font-light",
            "text-gray-600 dark:text-gray-300 bg-gray-50 dark:bg-gray-800/60",
            "active:bg-#{@accent}-100 active:text-#{@accent}-700",
            "border-l border-gray-200 dark:border-gray-700",
            "transition-colors duration-150 ease-out select-none"
          ]}
        >
          <span
            data-glyph
            class="inline-block transition-transform duration-150 ease-out [button:active>&]:scale-90 [button:active>&]:translate-y-px"
          >
            +
          </span>
        </button>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".AshFormStepper" runtime>
        {
          mounted() {
            this.input = this.el.querySelector('[data-part="value"]');
            this.dec = this.el.querySelector('[data-part="dec"]');
            this.inc = this.el.querySelector('[data-part="inc"]');
            this.min = this.el.dataset.min !== "" ? Number(this.el.dataset.min) : null;
            this.max = this.el.dataset.max !== "" ? Number(this.el.dataset.max) : null;
            this.step = Number(this.el.dataset.step || 1);

            this.bump = (dir) => {
              const cur = this.input.value === "" ? 0 : Number(this.input.value);
              let next = cur + dir * this.step;
              if (this.min !== null && next < this.min) next = this.min;
              if (this.max !== null && next > this.max) next = this.max;
              this.input.value = String(next);
              this.input.animate(
                [{ transform: "scale(1)" }, { transform: "scale(1.08)" }, { transform: "scale(1)" }],
                { duration: 180, easing: "cubic-bezier(.4,.0,.2,1)" }
              );
              this.input.dispatchEvent(new Event("input", { bubbles: true }));
              this.input.dispatchEvent(new Event("change", { bubbles: true }));
            };

            this.startHold = (dir) => {
              this.bump(dir);
              this.holdTimer = setTimeout(() => {
                this.holdInterval = setInterval(() => this.bump(dir), 80);
              }, 380);
            };
            this.stopHold = () => {
              clearTimeout(this.holdTimer);
              clearInterval(this.holdInterval);
            };

            ["pointerdown"].forEach(ev => {
              this.dec.addEventListener(ev, () => this.startHold(-1));
              this.inc.addEventListener(ev, () => this.startHold(+1));
            });
            ["pointerup", "pointerleave", "pointercancel"].forEach(ev => {
              this.dec.addEventListener(ev, () => this.stopHold());
              this.inc.addEventListener(ev, () => this.stopHold());
            });
          }
        }
      </script>
    </.field_wrapper>
    """
  end

  # ---------------------------------------------------------------------------
  # Multi-select combobox — searchable, creatable, chip-based
  # ---------------------------------------------------------------------------

  defp render_multiselect(assigns) do
    selected_values = list_string_values(assigns.form, assigns.field.name)
    options = normalize_options(assigns.field.options)
    base_name = Phoenix.HTML.Form.input_name(assigns.form, assigns.field.name)
    base_id = Phoenix.HTML.Form.input_id(assigns.form, assigns.field.name)
    creatable? = Keyword.get(assigns.field.opts || [], :creatable, true)
    resource = assigns.field.destination_resource
    create_action = Keyword.get(assigns.field.opts || [], :create_action, :create)

    selected_options =
      Enum.filter(options, fn {_, v} -> to_string(v) in selected_values end)

    component_target =
      Map.get(assigns, :component_target) ||
        Map.get(assigns, :target) ||
        Keyword.get(assigns.theme_opts || [], :target)

    assigns =
      assigns
      |> Map.merge(%{
        selected_values: selected_values,
        options: options,
        selected_options: selected_options,
        base_name: base_name,
        base_id: base_id,
        creatable?: creatable?,
        resource: resource,
        create_action: create_action,
        target: component_target
      })

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <div
        id={@base_id <> "_combobox"}
        phx-hook=".AshFormCombobox"
        phx-update="ignore"
        data-target={target_attr(@target)}
        data-field={@field.name}
        data-resource={resource_string(@resource)}
        data-action={@create_action}
        data-creatable={if @creatable?, do: "true", else: "false"}
        class={[
          "relative rounded-xl bg-white dark:bg-gray-900 ring-1 ring-inset shadow-sm",
          if(has_visible_error?(assigns),
            do: "ring-red-300 dark:ring-red-700",
            else: "ring-gray-200 dark:ring-gray-700"
          ),
          "focus-within:ring-2 focus-within:ring-#{@accent}-500",
          transition_classes(@transitions)
        ]}
      >
        <input type="hidden" name={@base_name <> "[]"} value="" />

        <div data-part="control" class="px-3 py-2.5 cursor-text">
          <div class="flex items-center gap-2">
            <input
              type="text"
              data-part="search"
              placeholder={@field.placeholder || "Search or add…"}
              autocomplete="off"
              class="flex-1 min-w-0 bg-transparent border-0 outline-none px-0 py-1 text-base sm:text-sm text-gray-900 dark:text-gray-100 placeholder:text-gray-400"
            />
            <button
              type="button"
              data-part="toggle"
              aria-label="Open options"
              class="inline-flex h-6 w-6 items-center justify-center rounded text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
            >
              <svg
                class="h-4 w-4 transition-transform [&]:duration-200"
                data-part="toggle-chevron"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 14l-5-5 1.4-1.4L10 11.2l3.6-3.6L15 9z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>

          <div
            data-part="pill-area"
            class="flex flex-wrap gap-1.5 mt-2.5 empty:hidden empty:mt-0"
          >
            <span
              :for={{label, value} <- @selected_options}
              data-part="pill"
              data-value={to_string(value)}
              class={pill_classes(@accent)}
            >
              <span class="truncate max-w-[12rem]">{label}</span>
              <button
                type="button"
                data-part="pill-remove"
                aria-label={"Remove #{label}"}
                class={"inline-flex h-4 w-4 items-center justify-center rounded-full text-#{@accent}-700 hover:bg-#{@accent}-200 dark:text-#{@accent}-200 dark:hover:bg-#{@accent}-800 transition-colors"}
              >
                <svg class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 0 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22z" />
                </svg>
              </button>
              <input type="hidden" name={@base_name <> "[]"} value={to_string(value)} />
            </span>
          </div>
        </div>

        <div
          data-part="dropdown"
          hidden={true}
          class="absolute left-0 right-0 top-full z-20 mt-1 max-h-64 overflow-y-auto rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shadow-lg py-1"
        >
          <button
            :for={{label, value} <- @options}
            type="button"
            data-part="option"
            data-value={to_string(value)}
            data-label={label}
            data-selected={if to_string(value) in @selected_values, do: "true", else: "false"}
            class={[
              "w-full flex items-center gap-2 px-3 py-2 text-sm text-left",
              "text-gray-700 dark:text-gray-200",
              "hover:bg-#{@accent}-50 dark:hover:bg-#{@accent}-950/30",
              "data-[selected=true]:bg-#{@accent}-50 dark:data-[selected=true]:bg-#{@accent}-950/40",
              "data-[selected=true]:font-medium"
            ]}
          >
            <span
              data-part="option-check"
              class={"inline-flex h-4 w-4 items-center justify-center rounded-full text-#{@accent}-600 #{if to_string(value) in @selected_values, do: "", else: "invisible"}"}
            >
              <svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path
                  fill-rule="evenodd"
                  d="M16.7 5.3a1 1 0 0 1 0 1.4l-7.5 7.5a1 1 0 0 1-1.4 0L3.3 9.7a1 1 0 0 1 1.4-1.4L8.5 12 15.3 5.3a1 1 0 0 1 1.4 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </span>
            <span class="flex-1 truncate">{label}</span>
          </button>

          <div
            data-part="empty"
            hidden={true}
            class="px-3 py-2 text-xs text-gray-500 dark:text-gray-400"
          >
            No matches.
          </div>

          <%= if @creatable? && @resource do %>
            <div
              data-part="create-divider"
              hidden={true}
              class="my-1 border-t border-gray-100 dark:border-gray-800"
            >
            </div>
            <button
              type="button"
              data-part="create"
              hidden={true}
              phx-click="create_combobox_item"
              phx-value-field={@field.name}
              phx-value-resource={resource_string(@resource)}
              phx-value-action={to_string(@create_action)}
              phx-value-creatable_value=""
              phx-target={@target}
              class={[
                "w-full flex items-center gap-2 px-3 py-2 text-sm text-left",
                "text-#{@accent}-700 dark:text-#{@accent}-300",
                "hover:bg-#{@accent}-50 dark:hover:bg-#{@accent}-950/30 font-medium"
              ]}
            >
              <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path d="M10 4a1 1 0 0 1 1 1v4h4a1 1 0 1 1 0 2h-4v4a1 1 0 1 1-2 0v-4H5a1 1 0 1 1 0-2h4V5a1 1 0 0 1 1-1z" />
              </svg>
              <span>Create "<span data-part="create-label"></span>"</span>
            </button>
          <% end %>
        </div>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".AshFormCombobox" runtime>
        {
          mounted() {
            this.controlEl = this.el.querySelector('[data-part="control"]');
            this.searchEl = this.el.querySelector('[data-part="search"]');
            this.pillAreaEl = this.el.querySelector('[data-part="pill-area"]');
            this.dropdownEl = this.el.querySelector('[data-part="dropdown"]');
            this.toggleEl = this.el.querySelector('[data-part="toggle"]');
            this.toggleChevron = this.el.querySelector('[data-part="toggle-chevron"]');
            this.emptyEl = this.el.querySelector('[data-part="empty"]');
            this.createEl = this.el.querySelector('[data-part="create"]');
            this.createDivider = this.el.querySelector('[data-part="create-divider"]');
            this.createLabel = this.el.querySelector('[data-part="create-label"]');
            this.options = Array.from(this.el.querySelectorAll('[data-part="option"]'));
            this.target = this.el.dataset.target;
            this.field = this.el.dataset.field;
            this.creatable = this.el.dataset.creatable === "true";

            this.openDropdown = () => {
              this.dropdownEl.hidden = false;
              if (this.toggleChevron) this.toggleChevron.classList.add("rotate-180");
            };
            this.closeDropdown = () => {
              this.dropdownEl.hidden = true;
              if (this.toggleChevron) this.toggleChevron.classList.remove("rotate-180");
            };
            this.isOpen = () => !this.dropdownEl.hidden;
            // Always start closed regardless of initial DOM state
            this.closeDropdown();

            this.controlEl.addEventListener("click", (e) => {
              if (e.target.closest('[data-part="pill-remove"]')) return;
              this.searchEl.focus();
              this.openDropdown();
            });

            this.searchEl.addEventListener("focus", () => this.openDropdown());
            this.searchEl.addEventListener("input", () => this.filter());
            this.searchEl.addEventListener("keydown", (e) => {
              if (e.key === "Escape") { this.closeDropdown(); }
              if (e.key === "Backspace" && this.searchEl.value === "") {
                const pills = this.el.querySelectorAll('[data-part="pill"]');
                const last = pills[pills.length - 1];
                if (last) this.removePill(last.dataset.value);
              }
              if (e.key === "Enter") {
                e.preventDefault();
                const visible = this.options.filter(o => !o.hidden);
                if (visible.length > 0) {
                  this.toggleOption(visible[0]);
                } else if (this.creatable && this.searchEl.value.trim() !== "") {
                  this.triggerCreate();
                }
              }
            });

            this.toggleEl.addEventListener("click", (e) => {
              e.stopPropagation();
              if (this.isOpen()) { this.closeDropdown(); } else { this.searchEl.focus(); this.openDropdown(); }
            });

            this.options.forEach(opt => {
              opt.addEventListener("click", (e) => {
                e.preventDefault();
                this.toggleOption(opt);
              });
            });

            this.el.querySelectorAll('[data-part="pill-remove"]').forEach(btn => {
              btn.addEventListener("click", (e) => {
                e.preventDefault();
                e.stopPropagation();
                const pill = btn.closest('[data-part="pill"]');
                if (pill) this.removePill(pill.dataset.value);
              });
            });

            this.docHandler = (e) => {
              if (!this.el.contains(e.target)) this.closeDropdown();
            };
            document.addEventListener("click", this.docHandler);

            this.handleEvent("ash_form_combobox_pill_added", ({field, id, label}) => {
              if (field !== this.field) return;
              if (this.el.querySelector(`[data-part="pill"][data-value="${CSS.escape(id)}"]`)) return;
              this.addPill(id, label);
              this.searchEl.value = "";
              this.filter();
              this.closeDropdown();
            });

            this.filter();
          },
          destroyed() {
            document.removeEventListener("click", this.docHandler);
          },
          filter() {
            const q = this.searchEl.value.trim().toLowerCase();
            let visible = 0;
            let exact = false;
            this.options.forEach(opt => {
              const label = (opt.dataset.label || opt.textContent).toLowerCase();
              const match = q === "" || label.includes(q);
              opt.hidden = !match;
              if (match) visible++;
              if (label === q) exact = true;
            });
            if (this.emptyEl) this.emptyEl.hidden = visible !== 0 || (this.creatable && q !== "");
            if (this.createEl) {
              const show = this.creatable && q !== "" && !exact;
              this.createEl.hidden = !show;
              if (this.createDivider) this.createDivider.hidden = !show || visible === 0;
              if (show && this.createLabel) this.createLabel.textContent = q;
              if (show) {
                this.createEl.setAttribute("phx-value-creatable_value", q);
              }
            }
          },
          toggleOption(opt) {
            const value = opt.dataset.value;
            const label = opt.dataset.label;
            const isSelected = opt.dataset.selected === "true";
            if (isSelected) {
              this.removePill(value);
            } else {
              this.addPill(value, label);
              opt.dataset.selected = "true";
              const check = opt.querySelector('[data-part="option-check"]');
              if (check) check.classList.remove("invisible");
            }
            this.searchEl.value = "";
            this.filter();
            this.searchEl.focus();
          },
          addPill(value, label) {
            const baseName = this.el.querySelector('input[type="hidden"]').name;
            const tpl = document.createElement("span");
            tpl.setAttribute("data-part", "pill");
            tpl.setAttribute("data-value", value);
            tpl.className = this.el.querySelector('[data-part="pill"]')?.className || "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800";
            tpl.innerHTML = `
              <span class="truncate max-w-[12rem]">${this.escape(label)}</span>
              <button type="button" data-part="pill-remove" aria-label="Remove ${this.escape(label)}" class="inline-flex h-4 w-4 items-center justify-center rounded-full hover:bg-black/10 transition-colors">
                <svg class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 0 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22z" /></svg>
              </button>
              <input type="hidden" name="${baseName}" value="${this.escape(value)}" />
            `;
            tpl.querySelector('[data-part="pill-remove"]').addEventListener("click", (e) => {
              e.preventDefault();
              e.stopPropagation();
              this.removePill(value);
            });
            (this.pillAreaEl || this.controlEl).appendChild(tpl);
            this.dispatchChange();
          },
          removePill(value) {
            const pill = this.el.querySelector(`[data-part="pill"][data-value="${CSS.escape(value)}"]`);
            if (pill) pill.remove();
            const opt = this.options.find(o => o.dataset.value === value);
            if (opt) {
              opt.dataset.selected = "false";
              const check = opt.querySelector('[data-part="option-check"]');
              if (check) check.classList.add("invisible");
            }
            this.dispatchChange();
          },
          triggerCreate() {
            if (!this.createEl) return;
            this.createEl.setAttribute("phx-value-creatable_value", this.searchEl.value.trim());
            this.createEl.click();
            this.searchEl.value = "";
          },
          dispatchChange() {
            const form = this.el.closest("form");
            if (form) form.dispatchEvent(new Event("change", { bubbles: true }));
          },
          escape(s) { return String(s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c])); }
        }
      </script>
    </.field_wrapper>
    """
  end

  # ---------------------------------------------------------------------------
  # Field renderers — boolean & multi-checkbox
  # ---------------------------------------------------------------------------

  defp render_checkbox(assigns) do
    checked? = boolean_value?(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :checked, checked?)

    ~H"""
    <div class={["mb-5", @field.wrapper_class]}>
      <label
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class={[
          "flex items-start gap-3 rounded-xl border border-gray-200 dark:border-gray-700",
          "px-3 py-3 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800/60",
          transition_classes(@transitions)
        ]}
      >
        <input type="hidden" name={Phoenix.HTML.Form.input_name(@form, @field.name)} value="false" />
        <input
          type="checkbox"
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value="true"
          checked={@checked}
          class={[checkbox_classes(@accent, @transitions), "mt-0.5", @field.class]}
        />
        <span class="flex-1 min-w-0">
          <span
            :if={@field.label}
            class="block text-sm font-medium text-gray-800 dark:text-gray-100"
          >
            {@field.label}<span :if={@field.required} class={"text-#{@accent}-600 ml-0.5"}>*</span>
          </span>
          <span :if={@field.hint} class="mt-0.5 block text-xs text-gray-500 dark:text-gray-400">
            {@field.hint}
          </span>
        </span>
      </label>
      <p
        :for={msg <- visible_errors(assigns)}
        class="mt-1.5 text-xs text-red-600 dark:text-red-400 flex items-center gap-1"
        role="alert"
      >
        <span aria-hidden="true">●</span>
        {msg}
      </p>
    </div>
    """
  end

  # iOS-style toggle switch — larger track, smoother thumb travel,
  # responsive label layout, accessible focus state.
  defp render_toggle(assigns) do
    checked? = boolean_value?(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :checked, checked?)

    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label
        class={[
          "group flex items-center justify-between gap-4 rounded-xl",
          "border border-gray-200 dark:border-gray-800",
          "bg-white dark:bg-gray-900 px-4 py-3.5",
          "cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800/60",
          "has-[:checked]:bg-#{@accent}-50/40 dark:has-[:checked]:bg-#{@accent}-950/20",
          "has-[:checked]:border-#{@accent}-200 dark:has-[:checked]:border-#{@accent}-900/60",
          transition_classes(@transitions)
        ]}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
      >
        <span class="flex-1 min-w-0">
          <span
            :if={@field.label}
            class="block text-sm font-medium text-gray-900 dark:text-gray-100"
          >
            {@field.label}<span :if={@field.required} class={"text-#{@accent}-600 ml-0.5"}>*</span>
          </span>
          <span :if={@field.hint} class="mt-0.5 block text-xs text-gray-500 dark:text-gray-400">
            {@field.hint}
          </span>
        </span>
        <span class="flex items-center gap-3 shrink-0">
          <span
            aria-hidden="true"
            class={[
              "text-[10px] font-semibold uppercase tracking-[0.08em] tabular-nums select-none",
              "text-gray-400 dark:text-gray-500",
              "group-has-[:checked]:text-#{@accent}-600 dark:group-has-[:checked]:text-#{@accent}-400",
              "transition-colors duration-200",
              "before:content-['Off'] group-has-[:checked]:before:content-['On']"
            ]}
          >
          </span>
          <span class="relative inline-block h-[31px] w-[51px] shrink-0">
            <input
              type="hidden"
              name={Phoenix.HTML.Form.input_name(@form, @field.name)}
              value="false"
            />
            <input
              type="checkbox"
              id={Phoenix.HTML.Form.input_id(@form, @field.name)}
              name={Phoenix.HTML.Form.input_name(@form, @field.name)}
              value="true"
              checked={@checked}
              class="peer sr-only"
            />
            <span class={[
              "absolute inset-0 rounded-full",
              "bg-gray-200 dark:bg-gray-700",
              "peer-checked:bg-#{@accent}-500",
              "shadow-inner",
              "peer-focus-visible:ring-2 peer-focus-visible:ring-offset-2 peer-focus-visible:ring-#{@accent}-500",
              "transition-colors duration-300 ease-in-out"
            ]}>
            </span>
            <span class={[
              "absolute top-[2px] left-[2px] h-[27px] w-[27px] rounded-full bg-white",
              "shadow-[0_2px_4px_rgba(0,0,0,0.12),0_3px_8px_rgba(0,0,0,0.15)]",
              "ring-1 ring-black/5",
              "peer-checked:translate-x-5",
              "transition-transform duration-300 ease-[cubic-bezier(.4,.2,.2,1)]"
            ]}>
            </span>
          </span>
        </span>
      </label>
      <p
        :for={msg <- visible_errors(assigns)}
        class="mt-1.5 text-xs text-red-600 dark:text-red-400 flex items-center gap-1"
        role="alert"
      >
        <span aria-hidden="true">●</span>
        {msg}
      </p>
    </div>
    """
  end

  # Compact chip-style choice group — flex-wraps cleanly, scales down to mobile.
  defp render_checkbox_group(assigns) do
    selected_values = list_string_values(assigns.form, assigns.field.name)
    options = checkbox_group_options(assigns.field)
    base_name = Phoenix.HTML.Form.input_name(assigns.form, assigns.field.name)

    assigns =
      assigns
      |> Map.put(:selected_values, selected_values)
      |> Map.put(:options, options)
      |> Map.put(:base_name, base_name)

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <input type="hidden" name={@base_name <> "[]"} value="" />
      <%= if @options == [] do %>
        <div class="rounded-xl border border-dashed border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/40 px-4 py-6 text-center">
          <p class="text-xs text-gray-500 dark:text-gray-400">
            No <span class="font-medium">{String.downcase(@field.label || "options")}</span>
            available yet.
          </p>
        </div>
      <% else %>
        <div class="flex flex-wrap gap-1.5">
          <label
            :for={{label, value} <- @options}
            class={[
              "group inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium cursor-pointer select-none whitespace-nowrap",
              "ring-1 ring-inset",
              if(to_string(value) in @selected_values,
                do:
                  "bg-#{@accent}-100 text-#{@accent}-800 ring-#{@accent}-500 dark:bg-#{@accent}-900/40 dark:text-#{@accent}-200 dark:ring-#{@accent}-700",
                else:
                  "bg-white text-gray-700 ring-gray-200 hover:ring-#{@accent}-400 hover:text-#{@accent}-700 dark:bg-gray-900 dark:text-gray-300 dark:ring-gray-700 dark:hover:text-#{@accent}-300"
              ),
              transition_classes(@transitions)
            ]}
          >
            <input
              type="checkbox"
              name={@base_name <> "[]"}
              value={to_string(value)}
              checked={to_string(value) in @selected_values}
              class="sr-only"
            />
            <svg
              :if={to_string(value) in @selected_values}
              class="h-3 w-3"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M16.7 5.3a1 1 0 0 1 0 1.4l-7.5 7.5a1 1 0 0 1-1.4 0L3.3 9.7a1 1 0 0 1 1.4-1.4L8.5 12 15.3 5.3a1 1 0 0 1 1.4 0z"
                clip-rule="evenodd"
              />
            </svg>
            <span>{label}</span>
          </label>
        </div>
      <% end %>
    </.field_wrapper>
    """
  end

  defp checkbox_group_options(field) do
    cond do
      is_list(field.options) and field.options != [] ->
        normalize_options(field.options)

      preload = Keyword.get(field.opts || [], :preload_options) ->
        normalize_options(preload)

      true ->
        []
    end
  end

  # ---------------------------------------------------------------------------
  # File upload — better drag-and-drop affordance
  # ---------------------------------------------------------------------------

  defp render_file_upload(assigns) do
    existing = existing_file_value(assigns.form, assigns.field.name)
    deleting? = file_delete_flag?(assigns.form, assigns.field.name)

    accept_label =
      case assigns.field.accept do
        nil -> "Any file"
        :any -> "Any file"
        :images -> "Images only"
        :documents -> "Documents only"
        :audio -> "Audio only"
        :video -> "Video only"
        list when is_list(list) -> Enum.join(list, ", ")
        bin when is_binary(bin) -> bin
        _ -> "Any file"
      end

    assigns =
      assigns
      |> Map.put(:existing, existing)
      |> Map.put(:deleting?, deleting?)
      |> Map.put(:accept_label, accept_label)
      |> Map.put(
        :component_target,
        Map.get(assigns, :component_target) || Map.get(assigns, :target)
      )

    ~H"""
    <.field_wrapper {field_wrapper_assigns(assigns)}>
      <%= if upload_config = Map.get(assigns[:uploads] || %{}, assigns.field.name) do %>
        <%= if @existing && !@deleting? do %>
          <div class={[
            "flex items-center gap-3 rounded-xl px-4 py-3",
            "bg-#{@accent}-50/60 dark:bg-#{@accent}-950/20",
            "ring-1 ring-inset ring-#{@accent}-100 dark:ring-#{@accent}-900/40",
            "mb-2"
          ]}>
            <%= if image_path?(@existing) do %>
              <img
                src={existing_url(@existing)}
                alt="Current file"
                class="h-12 w-12 rounded-lg object-cover ring-1 ring-black/5"
              />
            <% else %>
              <span class={"flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-white dark:bg-gray-900 text-#{@accent}-600 dark:text-#{@accent}-400"}>
                <svg
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25M9 16.5l3-3m0 0 3 3m-3-3v6m6.75-2.625V19.5a2.25 2.25 0 0 1-2.25 2.25h-9a2.25 2.25 0 0 1-2.25-2.25V11.25a2.25 2.25 0 0 1 2.25-2.25h2.625"
                  />
                </svg>
              </span>
            <% end %>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                {existing_filename(@existing)}
              </p>
              <p class="text-xs text-gray-500 dark:text-gray-400">Currently saved</p>
            </div>
            <button
              type="button"
              phx-click="toggle_file_delete"
              phx-value-field={@field.name}
              phx-target={@component_target}
              class="text-xs font-medium text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 transition-colors"
            >
              Remove
            </button>
          </div>
        <% end %>

        <%= if @deleting? do %>
          <div class="flex items-center justify-between gap-3 rounded-xl bg-red-50 dark:bg-red-950/30 px-4 py-3 ring-1 ring-inset ring-red-100 dark:ring-red-900/40 mb-2">
            <p class="text-xs text-red-700 dark:text-red-300">
              Existing file marked for deletion. Submit to confirm.
            </p>
            <button
              type="button"
              phx-click="toggle_file_delete"
              phx-value-field={@field.name}
              phx-target={@component_target}
              class="text-xs font-medium text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
            >
              Undo
            </button>
          </div>
        <% end %>

        <label
          for={upload_config.ref}
          phx-drop-target={upload_config.ref}
          class={[
            "group flex flex-col items-center justify-center gap-2 px-6 py-8",
            "rounded-xl border-2 border-dashed border-gray-300 dark:border-gray-700",
            "bg-gray-50/50 dark:bg-gray-900/40 cursor-pointer text-center",
            "hover:border-#{@accent}-500 hover:bg-#{@accent}-50/40 dark:hover:bg-#{@accent}-950/30",
            transition_classes(@transitions)
          ]}
        >
          <svg
            class={"h-10 w-10 text-gray-400 group-hover:text-#{@accent}-500 transition-colors"}
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5m-13.5-9L12 3m0 0 4.5 4.5M12 3v13.5"
            />
          </svg>
          <span class="text-sm font-medium text-gray-700 dark:text-gray-200">
            <%= if @existing && !@deleting? do %>
              Click or drop to replace
            <% else %>
              Click to upload or drag and drop
            <% end %>
          </span>
          <span class="text-[11px] text-gray-500 dark:text-gray-400 tabular-nums">
            {@accept_label} · max {format_max_size(upload_config.max_file_size)} · up to {upload_config.max_entries} file{upload_config.max_entries > 1 && "s"}
          </span>
          <.live_file_input upload={upload_config} class="sr-only" />
        </label>

        <%= for entry <- upload_config.entries do %>
          <div class={[
            "mt-2 flex items-center gap-3 rounded-xl px-3 py-2",
            "bg-white dark:bg-gray-900 ring-1 ring-inset ring-gray-200 dark:ring-gray-800"
          ]}>
            <%= if String.starts_with?(entry.client_type || "", "image/") do %>
              <.live_img_preview entry={entry} class="h-10 w-10 rounded-lg object-cover ring-1 ring-black/5" />
            <% else %>
              <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-500">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                </svg>
              </span>
            <% end %>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                {entry.client_name}
              </p>
              <div class="mt-1 h-1.5 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                <div
                  class={"h-full rounded-full bg-#{@accent}-500 transition-[width] duration-200"}
                  style={"width: #{entry.progress}%"}
                >
                </div>
              </div>
            </div>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              phx-target={@component_target}
              aria-label="Cancel upload"
              class="text-gray-400 hover:text-red-600 dark:text-gray-500 dark:hover:text-red-400"
            >
              <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 0 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22z" /></svg>
            </button>
          </div>
          <%= for err <- upload_errors(upload_config, entry) do %>
            <p class="mt-1 text-xs text-red-600 dark:text-red-400">{translate_upload_error(err)}</p>
          <% end %>
        <% end %>
        <%= for err <- upload_errors(upload_config) do %>
          <p class="mt-1 text-xs text-red-600 dark:text-red-400">{translate_upload_error(err)}</p>
        <% end %>
      <% else %>
        <p class="rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs text-amber-800 dark:border-amber-800 dark:bg-amber-950/40 dark:text-amber-200">
          File upload not configured for this field.
        </p>
      <% end %>
    </.field_wrapper>
    """
  end

  defp file_delete_flag?(form, field_name) do
    delete_key = "#{field_name}_delete"

    cond do
      Phoenix.HTML.Form.input_value(form, delete_key) in [true, "true", "on", 1, "1"] ->
        true

      true ->
        false
    end
  end

  defp existing_file_value(form, field_name) do
    case Phoenix.HTML.Form.input_value(form, field_name) do
      nil -> nil
      "" -> nil
      [] -> nil
      v when is_list(v) -> List.first(v)
      v -> v
    end
  end

  defp existing_filename(path) when is_binary(path), do: Path.basename(path)
  defp existing_filename(_), do: ""

  defp existing_url(path) when is_binary(path) do
    if String.starts_with?(path, ["http://", "https://", "/"]),
      do: path,
      else: "/" <> path
  end

  defp existing_url(_), do: ""

  defp image_path?(path) when is_binary(path) do
    String.match?(path, ~r/\.(jpe?g|png|gif|webp|svg|avif)$/i)
  end

  defp image_path?(_), do: false

  defp format_max_size(bytes) when bytes >= 1_000_000_000,
    do: "#{Float.round(bytes / 1_000_000_000, 1)} GB"

  defp format_max_size(bytes) when bytes >= 1_000_000,
    do: "#{Float.round(bytes / 1_000_000, 1)} MB"

  defp format_max_size(bytes) when bytes >= 1_000,
    do: "#{Float.round(bytes / 1_000, 1)} KB"

  defp format_max_size(bytes), do: "#{bytes} B"

  defp translate_upload_error(:too_large), do: "File is too large"
  defp translate_upload_error(:too_many_files), do: "Too many files"
  defp translate_upload_error(:not_accepted), do: "File type not accepted"
  defp translate_upload_error(:external_client_failure), do: "Upload failed"
  defp translate_upload_error(other) when is_atom(other), do: humanize_atom(other)
  defp translate_upload_error(other) when is_binary(other), do: other
  defp translate_upload_error(other), do: inspect(other)

  defp humanize_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  # ---------------------------------------------------------------------------
  # Shared field wrapper (label + slot + hint + errors)
  # ---------------------------------------------------------------------------

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:field, :any, required: true)
  attr(:accent, :atom, default: :indigo)
  attr(:show_errors?, :boolean, default: false)
  slot(:inner_block, required: true)

  defp field_wrapper(assigns) do
    ~H"""
    <div class={["mb-5", @field.wrapper_class]}>
      <div :if={@field.label || @field.description} class="mb-1.5">
        <label
          :if={@field.label}
          for={Phoenix.HTML.Form.input_id(@form, @field.name)}
          class="block text-sm font-medium text-gray-800 dark:text-gray-100"
        >
          {@field.label}<span :if={@field.required} class={"text-#{@accent}-600 ml-0.5"}>*</span>
        </label>
        <p :if={@field.description} class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
          {@field.description}
        </p>
      </div>

      {render_slot(@inner_block)}

      <p
        :if={@field.hint && !@show_errors?}
        class="mt-1.5 text-xs text-gray-500 dark:text-gray-400"
      >
        {@field.hint}
      </p>

      <p
        :for={msg <- visible_error_messages(@form, @field.name, @show_errors?)}
        class="mt-1.5 text-xs text-red-600 dark:text-red-400 flex items-center gap-1.5"
        role="alert"
      >
        <svg class="h-4 w-4 shrink-0" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zm-1-7V5a1 1 0 112 0v6a1 1 0 11-2 0zm1 4a1 1 0 110-2 1 1 0 010 2z"
            clip-rule="evenodd"
          />
        </svg>
        {msg}
      </p>
    </div>
    """
  end

  defp field_wrapper_assigns(assigns) do
    %{
      form: assigns.form,
      field: assigns.field,
      accent: assigns.accent,
      show_errors?: form_touched?(assigns.form, assigns.field.name)
    }
  end

  # ---------------------------------------------------------------------------
  # Tailwind class builders
  # ---------------------------------------------------------------------------

  defp input_classes(accent, transitions, has_errors?) do
    base = [
      "block w-full rounded-xl border-0",
      "px-4 py-3.5 text-base",
      "sm:px-3.5 sm:py-2.5 sm:text-[15px]",
      "lg:text-sm",
      "leading-snug",
      "text-gray-900 dark:text-gray-100",
      "bg-white dark:bg-gray-900",
      "shadow-sm ring-1 ring-inset",
      "placeholder:text-gray-400 dark:placeholder:text-gray-500",
      "focus:outline-none focus:ring-2 focus:ring-inset",
      "disabled:opacity-60 disabled:cursor-not-allowed",
      "read-only:bg-gray-50 dark:read-only:bg-gray-800/50"
    ]

    ring =
      if has_errors? do
        ["ring-red-300 dark:ring-red-700", "focus:ring-red-500"]
      else
        ["ring-gray-200 dark:ring-gray-700", "focus:ring-#{accent}-500"]
      end

    motion =
      case transitions do
        :none -> []
        :subtle -> ["transition duration-150"]
        :smooth -> ["transition duration-200"]
      end

    Enum.join(base ++ ring ++ motion, " ")
  end

  defp checkbox_classes(accent, transitions) do
    base = [
      "h-4 w-4 rounded border-gray-300 dark:border-gray-600",
      "text-#{accent}-600 focus:ring-#{accent}-500 focus:ring-offset-0"
    ]

    motion =
      case transitions do
        :none -> []
        :subtle -> ["transition-colors duration-150"]
        :smooth -> ["transition-all duration-200"]
      end

    Enum.join(base ++ motion, " ")
  end

  defp pill_classes(accent) do
    Enum.join(
      [
        "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium",
        "bg-#{accent}-100 text-#{accent}-800 ring-1 ring-inset ring-#{accent}-200",
        "dark:bg-#{accent}-900/40 dark:text-#{accent}-200 dark:ring-#{accent}-700"
      ],
      " "
    )
  end

  defp transition_classes(:none), do: ""
  defp transition_classes(:subtle), do: "transition duration-150"
  defp transition_classes(:smooth), do: "transition duration-200"

  # ---------------------------------------------------------------------------
  # Icons
  # ---------------------------------------------------------------------------

  attr(:name, :atom, required: true)
  attr(:class, :string, default: "h-5 w-5")

  defp field_icon(%{name: :calendar} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3.75 8.25h16.5M4.5 6h15a1.5 1.5 0 0 1 1.5 1.5v12A1.5 1.5 0 0 1 19.5 21h-15A1.5 1.5 0 0 1 3 19.5v-12A1.5 1.5 0 0 1 4.5 6Z" />
    </svg>
    """
  end

  defp field_icon(%{name: :clock} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6l4 2m5-2a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
    </svg>
    """
  end

  defp field_icon(assigns), do: ~H""

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_options(options) when is_list(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value when is_atom(value) -> {Phoenix.Naming.humanize(value), value}
      value -> {to_string(value), value}
    end)
  end

  defp normalize_options(_), do: []

  defp selected?(nil, _), do: false
  defp selected?(form_value, opt_value), do: to_string(form_value) == to_string(opt_value)

  defp boolean_value?(form, field_name) do
    Phoenix.HTML.Form.input_value(form, field_name) in [true, "true", "on", 1, "1"]
  end

  defp list_string_values(form, field_name) do
    case Phoenix.HTML.Form.input_value(form, field_name) do
      nil -> []
      v when is_list(v) -> Enum.map(v, &to_string/1)
      v -> [to_string(v)]
    end
  end

  defp resource_string(nil), do: nil
  defp resource_string(mod) when is_atom(mod), do: to_string(mod)

  defp target_attr(nil), do: nil
  defp target_attr(target) when is_binary(target), do: target
  defp target_attr(other), do: inspect(other)

  defp form_touched?(%Phoenix.HTML.Form{source: source}, field_name) do
    case source do
      %AshPhoenix.Form{} = ash ->
        ash.submitted_once? or field_in_touched?(ash.touched_forms, field_name)

      _ ->
        false
    end
  end

  defp form_touched?(_, _), do: false

  defp field_in_touched?(touched_forms, field_name) do
    name = to_string(field_name)
    Enum.any?(touched_forms, &(&1 == name))
  end

  defp visible_errors(assigns) do
    visible_error_messages(
      assigns.form,
      assigns.field.name,
      form_touched?(assigns.form, assigns.field.name)
    )
  end

  defp has_visible_error?(assigns) do
    visible_errors(assigns) != []
  end

  defp visible_error_messages(_form, _field_name, false), do: []

  defp visible_error_messages(form, field_name, true) do
    error_messages(form, field_name)
  end

  defp error_messages(form, field_name) do
    case form do
      %Phoenix.HTML.Form{} ->
        case form[field_name] do
          %Phoenix.HTML.FormField{errors: errs} when is_list(errs) ->
            Enum.map(errs, &translate_error/1)

          _ ->
            []
        end

      _ ->
        []
    end
  end

  defp translate_error({msg, opts}) when is_binary(msg) do
    Enum.reduce(opts, msg, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg
  defp translate_error(other), do: inspect(other)

  defp html_input_type(:text_input), do: "text"
  defp html_input_type(:number), do: "number"
  defp html_input_type(:email), do: "email"
  defp html_input_type(:password), do: "password"
  defp html_input_type(:date), do: "date"
  defp html_input_type(:datetime), do: "datetime-local"
  defp html_input_type(:url), do: "url"
  defp html_input_type(:tel), do: "tel"
  defp html_input_type(_), do: "text"

  defp format_date_display(value, type, placeholder) do
    case to_string(value) do
      "" -> placeholder || default_date_placeholder(type)
      raw -> format_date_string(raw, type) || raw
    end
  end

  defp default_date_placeholder(:datetime), do: "Pick date & time"
  defp default_date_placeholder(_), do: "Pick a date"

  defp format_date_string(raw, :datetime) do
    with {:ok, dt} <- parse_datetime(raw) do
      Calendar.strftime(dt, "%a, %b %-d %Y · %-I:%M %p")
    else
      _ -> nil
    end
  end

  defp format_date_string(raw, _) do
    case Date.from_iso8601(raw) do
      {:ok, date} -> Calendar.strftime(date, "%a, %b %-d %Y")
      _ -> nil
    end
  end

  defp parse_datetime(raw) do
    case NaiveDateTime.from_iso8601(raw) do
      {:ok, ndt} -> {:ok, ndt}
      _ -> NaiveDateTime.from_iso8601(raw <> ":00")
    end
  end

  defp wheel_col_classes do
    [
      "block h-full overflow-y-auto snap-y snap-mandatory",
      "tabular-nums text-center text-base list-none m-0 p-0",
      "[scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
      "[mask-image:linear-gradient(to_bottom,transparent_0%,black_28%,black_72%,transparent_100%)]",
      "[-webkit-mask-image:linear-gradient(to_bottom,transparent_0%,black_28%,black_72%,transparent_100%)]",
      "[scroll-behavior:smooth] [scroll-snap-stop:always]",
      "[-webkit-overflow-scrolling:touch]",
      "overscroll-contain will-change-scroll"
    ]
  end

  defp wheel_item_classes do
    [
      "h-10 flex items-center justify-center snap-center snap-always cursor-pointer",
      "text-gray-500 dark:text-gray-400",
      "data-[active=true]:text-gray-900 dark:data-[active=true]:text-white data-[active=true]:font-semibold",
      "transition-colors"
    ]
  end

  defp month_short(1), do: "Jan"
  defp month_short(2), do: "Feb"
  defp month_short(3), do: "Mar"
  defp month_short(4), do: "Apr"
  defp month_short(5), do: "May"
  defp month_short(6), do: "Jun"
  defp month_short(7), do: "Jul"
  defp month_short(8), do: "Aug"
  defp month_short(9), do: "Sep"
  defp month_short(10), do: "Oct"
  defp month_short(11), do: "Nov"
  defp month_short(12), do: "Dec"

  defp year_range do
    current = Date.utc_today().year
    (current - 80)..(current + 30)
  end
end
