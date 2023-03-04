
|                        Method |         Mean |        Error |       StdDev |    Ratio | RatioSD |   Gen0 |   Gen1 | Allocated | Alloc Ratio |
|------------------------------ |-------------:|-------------:|-------------:|---------:|--------:|-------:|-------:|----------:|------------:|
| ChainOfResponsibilityExplicit |     97.97 ns |     0.937 ns |     0.876 ns |     1.44 |    0.01 |      - |      - |         - |          NA |
| ChainOfResponsibilityInferred |  3,406.78 ns |    12.008 ns |    10.645 ns |    50.31 |    0.14 | 0.2594 |      - |    1096 B |          NA |
|                  UsingMediatR | 76,356.00 ns | 1,231.108 ns | 1,151.580 ns | 1,125.14 |   15.08 | 1.9531 | 0.9766 |    8268 B |          NA |
|                     PlainCode |     67.72 ns |     0.204 ns |     0.170 ns |     1.00 |    0.00 |      - |      - |         - |          NA |


