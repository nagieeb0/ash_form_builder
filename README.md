# Ash Form Builder 🚀

A declarative form generation engine for [Ash Framework](https://ash-hq.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html). 

Define your form structures directly inside your `Ash.Resource` domain layer, and let the engine automatically generate the Phoenix form modules, nested configurations, and LiveView components.

## ✨ Features

* **🛠️ Declarative DSL:** Define form fields, types, and labels directly in your resource.
* **🔄 Multiple Actions:** Support for both `:create` and `:update` forms with separate configurations.
* **🔗 Nested Forms:** Native support for `has_many` and `belongs_to` nested forms, complete with dynamic "add" and "remove" actions.
* **⚡ Self-Contained LiveComponent:** A ready-to-use `<.live_component>` that handles validation, submission, and nested form state automatically.

---

## 📦 Installation

Add `ash_form_builder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash, "~> 3.0"},
    {:ash_phoenix, "~> 2.0"},
    {:ash_form_builder, github: "nagieeb0/ash_form_builder"} 
  ]
end

🚀 Usage Example (Todo App)
1. Define Forms in Your Resource

Use the form do ... end DSL to define how your actions should be rendered. You can define multiple forms for different actions (e.g., Create vs. Update).
Elixir

defmodule MyApp.Todos.Todo do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]
    
  # ... attributes, relationships, actions ...

  # Create form  
  form do  
    action(:create)  
    submit_label("Create Todo")  
  
    field :title do  
      label("Title")  
      required(true)  
    end  

    nested :subtasks do  
      cardinality(:many)  
      add_label("Add subtask")  
  
      field :title do  
        label("Subtask")  
      end  
    end  
  end  

  # Update form (using a custom module to avoid conflicts)
  form do  
    action(:update)  
    module(MyApp.Todos.Todo.UpdateForm)  
  
    field :title do  
      label("Title")  
    end  
    
    field :completed do  
      label("Completed?")  
      type(:checkbox)  
    end  
  end  
end

2. Create the Form in LiveView

The extension generates helper modules at compile-time to instantly create AshPhoenix.Form instances with all nested configs pre-loaded.
Elixir

# For a new record:
form = MyApp.Todos.Todo.Form.for_create(actor: current_user)

# For an existing record:
todo = Ash.get!(MyApp.Todos.Todo, id)
form = MyApp.Todos.Todo.UpdateForm.for_update(todo, actor: current_user)

3. Render the Component

Drop the AshFormBuilder.FormComponent into your template. It handles validation, nested additions/removals, and submission automatically.
Elixir

<.live_component  
  module={AshFormBuilder.FormComponent}  
  id="todo-form"  
  form={@form}  
/>

4. Handle the Submission

On successful save, the component sends a message to the parent LiveView:
Elixir

def handle_info({:form_submitted, MyApp.Todos.Todo, result}, socket) do  
  # result is the newly created or updated record
  {:noreply, push_patch(socket, to: ~p"/todos")}  
end

📝 License

This project is MIT licensed.
