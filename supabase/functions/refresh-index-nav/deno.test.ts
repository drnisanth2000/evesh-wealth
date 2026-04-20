// Unit test for parseNseCsv. Run with `deno test`.
import { assertEquals } from 'https://deno.land/std@0.208.0/assert/mod.ts';
import { parseNseCsv } from './index.ts';

Deno.test('parseNseCsv reads NSE-style historical CSV', async () => {
  const csv = await Deno.readTextFile(
    new URL('./__fixtures__/nifty50_sample.csv', import.meta.url),
  );
  const points = parseNseCsv(csv);
  assertEquals(points.length, 5);
  assertEquals(points[0].date, '2024-01-01');
  assertEquals(points[0].nav, 21595.4);
  assertEquals(points[4].date, '2024-01-05');
  assertEquals(points[4].nav, 21720.15);
});

Deno.test('parseNseCsv handles empty input', () => {
  assertEquals(parseNseCsv(''), []);
  assertEquals(parseNseCsv('header only'), []);
});
