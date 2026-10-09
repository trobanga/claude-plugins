# LiveView JavaScript interop

- A hook that manages its own DOM needs `phx-update="ignore"` beside `phx-hook`, or the next patch overwrites it.
- Every `phx-hook` needs a unique DOM id; without one the compiler raises.

A hook is either colocated, defined in the HEEx, or external, defined in `assets/js/`.

## Colocated hooks

A raw `<script>` in HEEx does not work with LiveView. Write a colocated hook instead, a `<script>` with `:type={Phoenix.LiveView.ColocatedHook}`. Its name starts with a `.`, and LiveView bundles it into `app.js`:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

## External hooks

An external hook lives in `assets/js/` and is passed to the `LiveSocket` constructor:

    const MyHook = {
      mounted() { ... }
    }
    let liveSocket = new LiveSocket("/live", Socket, {
      hooks: { MyHook }
    });

    <div id="myhook" phx-hook="MyHook"></div>

## Events between server and client

`push_event/3` sends data to a hook. It returns a new socket, so return or rebind it:

    socket = push_event(socket, "my_event", %{...})

    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

The hook receives it with `this.handleEvent`:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

A hook sends an event and takes a reply with `this.pushEvent`:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
      })
    }

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end
