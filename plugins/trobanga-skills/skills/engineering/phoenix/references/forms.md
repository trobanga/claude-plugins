# Forms

Drive every form from an assign made by `to_form/2` in the LiveView, render it with `<.form for={@form} id="...">`, and read fields as `@form[:field]` through `<.input>`. Give every form an explicit, unique DOM id.

    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

The template never touches the changeset. These fail:

    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

    <.form let={f} ...>

## From params

`to_form/1` on a map takes it as the form params, with string keys:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

`as:` nests the params under a name:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

## From a changeset

A changeset gives the form its data, params and errors, and `as:` comes from the schema. For a `MyApp.Users.User`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

The submitted params arrive as `%{"user" => user_params}`:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>
