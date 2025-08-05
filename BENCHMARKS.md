# Mau Template Engine Benchmarks

This document presents the performance benchmarks for the Mau template engine, comparing it against other popular Elixir templating libraries: Solid and Liquex.

## Full Render Performance

The following table summarizes the results of the full render benchmark, which measures the time taken to parse a template and render it with a given context. The benchmarks were run on an Apple M1 with 16GB of RAM, using Elixir 1.18.1 and Erlang 25.3.2.7.

| Scenario                 | Mau (parse+render) | Solid (parse+render) | Liquex (parse+render) | Winner |
| ------------------------ | ------------------ | -------------------- | --------------------- | ------ |
| **Simple Text**          | **434.95 K ips**   | 364.34 K ips         | 148.36 K ips          | **Mau**|
| **Variable Interpolation** | 52.20 K ips        | **72.51 K ips**      | 18.07 K ips           | **Solid**|
| **Property Access**      | **43.82 K ips**    | 43.35 K ips          | 16.89 K ips           | **Mau**|
| **Simple Conditionals**  | 58.71 K ips        | **70.87 K ips**      | 24.38 K ips           | **Solid**|
| **Complex Conditionals** | **22.00 K ips**    | 18.82 K ips          | 8.43 K ips            | **Mau**|
| **Simple Loop**          | 41.15 K ips        | **46.45 K ips**      | 11.69 K ips           | **Solid**|
| **Nested Loop**          | **13.73 K ips**    | 11.78 K ips          | 3.36 K ips            | **Mau**|
| **Assignment and Logic** | **16.57 K ips**    | 14.84 K ips          | 5.56 K ips            | **Mau**|
| **Complex Template**     | **4.34 K ips**     | 3.33 K ips           | 1.00 K ips            | **Mau**|

## Memory Usage

The following table summarizes the memory usage for each engine during the benchmark.

| Scenario                 | Mau (parse+render) | Solid (parse+render) | Liquex (parse+render) | Winner (Lowest Memory) |
| ------------------------ | ------------------ | -------------------- | --------------------- | ---------------------- |
| **Simple Text**          | 3.55 KB            | **3.49 KB**          | 13.22 KB              | **Solid**              |
| **Variable Interpolation** | 32.55 KB           | **13.50 KB**         | 40.50 KB              | **Solid**              |
| **Property Access**      | 39.38 KB           | **19.64 KB**         | 49.80 KB              | **Solid**              |
| **Simple Conditionals**  | 31.05 KB           | **13.38 KB**         | 41.91 KB              | **Solid**              |
| **Complex Conditionals** | 81.14 KB           | **41.35 KB**         | 113.41 KB             | **Solid**              |
| **Simple Loop**          | 39.62 KB           | **16.05 KB**         | 28.16 KB              | **Solid**              |
| **Nested Loop**          | 115.98 KB          | **54.43 KB**         | 111.56 KB             | **Solid**              |
| **Assignment and Logic** | 101.56 KB          | **44.20 KB**         | 62.46 KB              | **Solid**              |
| **Complex Template**     | 382.30 KB          | **276.20 KB**        | 1055.16 KB            | **Solid**              |

## Version Comparison

This section compares the performance and memory usage of the Mau template engine between the old and new versions.

### Performance (Iterations per Second)

| Scenario                 | Mau (Old Version) | Mau (New Version) | Change     |
| ------------------------ | ----------------- | ----------------- | ---------- |
| **Simple Text**          | 417.38 K ips      | 461.89 K ips      | **+10.66%** |
| **Variable Interpolation** | 49.56 K ips       | 53.58 K ips       | **+8.11%** |
| **Property Access**      | 42.87 K ips       | 45.04 K ips       | **+5.06%** |
| **Simple Conditionals**  | 58.72 K ips       | 60.46 K ips       | **+2.96%** |
| **Complex Conditionals** | 21.39 K ips       | 22.49 K ips       | **+5.14%** |
| **Simple Loop**          | 41.21 K ips       | 43.44 K ips       | **+5.41%** |
| **Nested Loop**          | 13.57 K ips       | 13.91 K ips       | **+2.51%** |
| **Assignment and Logic** | 16.06 K ips       | 16.75 K ips       | **+4.30%** |
| **Complex Template**     | 4.16 K ips        | 4.12 K ips        | **-0.96%** |

### Memory Usage

| Scenario                 | Mau (Old Version) | Mau (New Version) | Change     |
| ------------------------ | ----------------- | ----------------- | ---------- |
| **Simple Text**          | 3.55 KB           | 3.33 KB           | **-6.20%** |
| **Variable Interpolation** | 33.22 KB          | 32.10 KB          | **-3.37%** |
| **Property Access**      | 40.16 KB          | 39 KB             | **-2.89%** |
| **Simple Conditionals**  | 31.75 KB          | 30.69 KB          | **-3.34%** |
| **Complex Conditionals** | 83.20 KB          | 80.67 KB          | **-3.04%** |
| **Simple Loop**          | 41.07 KB          | 39.48 KB          | **-3.87%** |
| **Nested Loop**          | 119.72 KB         | 115.70 KB         | **-3.36%** |
| **Assignment and Logic** | 106.02 KB         | 101.34 KB         | **-4.41%** |
| **Complex Template**     | 391.73 KB         | 380.52 KB         | **-2.86%** |