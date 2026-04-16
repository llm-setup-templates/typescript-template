# Test Modification Scenarios — TypeScript / Next.js

Three concrete scenarios demonstrating `.claude/rules/test-modification.md` in action.
Each scenario starts from a working Next.js project with passing tests.

---

## Scenario A: Add GET /api/items route

**Code change type**: API route added
**Affected layers**: unit + integration + snapshot

### Code change

```typescript
// src/app/api/items/route.ts (new file)
import { NextResponse } from "next/server";

interface Item {
  id: number;
  name: string;
  price: number;
}

const ITEMS: Item[] = [
  { id: 1, name: "Widget", price: 9.99 },
  { id: 2, name: "Gadget", price: 24.99 },
];

export function GET() {
  return NextResponse.json(ITEMS);
}
```

### Required test changes

**1. Unit test** — `__tests__/api/items.test.ts` (new file)

```typescript
import { GET } from "@/app/api/items/route";

describe("GET /api/items", () => {
  it("returns items array", async () => {
    const response = await GET();
    const data = await response.json();

    expect(data).toHaveLength(2);
    expect(data[0]).toMatchObject({ id: 1, name: "Widget" });
  });

  it("returns 200 status", async () => {
    const response = await GET();
    expect(response.status).toBe(200);
  });
});
```

**2. Snapshot test** — `__tests__/api/items.snapshot.test.ts` (new file)

```typescript
import { GET } from "@/app/api/items/route";

describe("GET /api/items snapshot", () => {
  it("matches response shape", async () => {
    const response = await GET();
    const data = await response.json();
    expect(data).toMatchSnapshot();
  });
});
```

Run `npm test` — Jest auto-creates the snapshot on first run.

---

## Scenario B: Add lastUpdated field to health response

**Code change type**: Response schema changed
**Affected layers**: unit (existing) + snapshot (existing breaks)

### Code change

```typescript
// src/app/api/health/route.ts — modify response
export function GET() {
  return NextResponse.json({
    status: "ok",
    version: "0.1.0",
    lastUpdated: new Date().toISOString(), // NEW — dynamic!
  });
}
```

### What happens

1. `npm test` → **snapshot test fails** (response now has `lastUpdated`)
2. Read the snapshot diff:
   ```diff
   + "lastUpdated": "2026-04-16T12:00:00.000Z",
   ```
3. Ask: "Did I intentionally add this field?" → **YES**
4. But `lastUpdated` is **dynamic** — different every run!

### Correct approach

Do NOT snapshot the dynamic field. Fix the test:

```typescript
it("matches response shape", async () => {
  const response = await GET();
  const data = await response.json();
  expect(data).toMatchObject({
    status: "ok",
    version: "0.1.0",
    lastUpdated: expect.any(String), // dynamic — use matcher
  });
});
```

Or mock `Date`:

```typescript
beforeEach(() => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date("2026-01-01T00:00:00Z"));
});
afterEach(() => jest.useRealTimers());
```

### What NOT to do

- Do NOT run `npm test -- -u` without reading the diff first
- Do NOT delete the snapshot test because it failed
- Do NOT snapshot `lastUpdated` without mocking Date — it will fail on next run

---

## Scenario C: Refactor route handler (extract service)

**Code change type**: Refactoring (behavior unchanged)
**Affected layers**: none

### Code change

```typescript
// src/features/health/health.service.ts (new file — extracted)
export function getHealthStatus() {
  return { status: "ok", version: "0.1.0" };
}
```

```typescript
// src/app/api/health/route.ts (modified — uses service)
import { NextResponse } from "next/server";
import { getHealthStatus } from "@/features/health/health.service";

export function GET() {
  return NextResponse.json(getHealthStatus());
}
```

### Required test changes

**None.** All existing tests must pass without modification.

- `npm test` → all green → refactoring is correct
- If any test fails → the refactoring changed behavior → **fix the code, not the tests**

### Common mistakes

- Adding unit tests for `health.service.ts` — unnecessary if existing integration test already covers the behavior via `/api/health`
- Updating import paths in tests — only needed if tests directly imported from the old location
