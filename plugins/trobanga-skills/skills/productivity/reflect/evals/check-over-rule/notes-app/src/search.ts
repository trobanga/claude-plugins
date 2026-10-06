import { search } from "./api";
import { debounce } from "./util/debounce";

export function attach(input: HTMLInputElement, render: (r: unknown) => void) {
  input.addEventListener("input", debounce(async () => {
    const results = await search(input.value);
    render(Object.groupBy(results, (r: { notebook: string }) => r.notebook));
  }, 300));
}
