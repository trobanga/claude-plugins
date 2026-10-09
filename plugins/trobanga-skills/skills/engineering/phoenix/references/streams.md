# LiveView streams

Render a collection through a stream. A list assign keeps every item in the socket, and a large one balloons memory until the process is killed.

## Operations

- Append items: `stream(socket, :messages, [new_msg])`
- Reset with new items, for example after a filter: `stream(socket, :messages, [new_msg], reset: true)`
- Prepend: `stream(socket, :messages, [new_msg], at: -1)`
- Delete: `stream_delete(socket, :messages, msg)`

## Template

The parent carries `phx-update="stream"` and a DOM id. Each child takes its id from the stream:

    <div id="messages" phx-update="stream">
      <div :for={{id, msg} <- @streams.messages} id={id}>
        {msg.text}
      </div>
    </div>

## Filtering

A stream is not enumerable: `Enum.filter/2` and `Enum.reject/2` do not work on it. To filter, prune or refresh, fetch the data again and reset the stream:

    def handle_event("filter", %{"filter" => filter}, socket) do
      messages = list_messages(filter)

      {:noreply,
       socket
       |> assign(:messages_empty?, messages == [])
       |> stream(:messages, messages, reset: true)}
    end

## Counts and empty states

A stream holds no count. Keep a count in a separate assign. For an empty state, use Tailwind's `only:`, which works only when the empty state is the one other child beside the comprehension:

    <div id="tasks" phx-update="stream">
      <div class="hidden only:block">No tasks yet</div>
      <div :for={{id, task} <- @streams.tasks} id={id}>
        {task.name}
      </div>
    </div>

## Updating an item

When an assign changes what a streamed item draws, insert the item again with the assign:

    def handle_event("edit_message", %{"message_id" => message_id}, socket) do
      message = Chat.get_message!(message_id)
      edit_form = to_form(Chat.change_message(message, %{content: message.content}))

      {:noreply,
       socket
       |> stream_insert(:messages, message)
       |> assign(:editing_message_id, String.to_integer(message_id))
       |> assign(:edit_form, edit_form)}
    end

    <div id="messages" phx-update="stream">
      <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
        {message.username}
        <%= if @editing_message_id == message.id do %>
          <.form for={@edit_form} id={"edit-form-#{message.id}"} phx-submit="save_edit">
            ...
          </.form>
        <% end %>
      </div>
    </div>
