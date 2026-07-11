# Comparative Analysis of I2P and Tor Network Architectures

**Impact on Bandwidth and Latency Performance**

Authors: Masum Uddin (U3260592), Jude Lazarus (U3254832), Kasra Zahedpur (U3239109)

## Abstract

This research paper presents a technical evaluation of the network architectures of **I2P** and **Tor**, focusing on how their architectural decisions affect latency and bandwidth. Using controlled HTTP-GET requests and full website load tests across a sample of 500 popular websites, we measured core latency, average (page-load) latency, and bandwidth for both networks, comparing unidirectional tunnel routing (I2P) against bidirectional circuit routing (Tor). The results show that while I2P offers marginal advantages for very simple requests in some cases, its performance degrades significantly for more complex browsing and file downloads compared to Tor.

## Repository Contents

```
.
├── paper/
│   └── I2P_vs_Tor_Comparative_Analysis.pdf   # Full research paper
├── scripts/
│   └── perl/                                 # Perl scripts used for latency/bandwidth testing
├── data/
│   └── results/                              # Raw/processed measurement data
├── figures/
│   └── ...                                   # Charts/graphs used in the paper
└── README.md
```

*(Adjust folder/file names to match what you actually include — see suggestions below.)*

## Background

Peer-to-peer (P2P) anonymity networks like **I2P (Invisible Internet Project)** and **Tor (The Onion Router)** provide anonymous communication by routing traffic through multiple intermediary nodes, but they take fundamentally different architectural approaches:

- **Tor** uses **onion routing** with bidirectional circuits — a single tunnel handles both inbound and outbound traffic through Entry, Relay, and Exit nodes, using layered (multi-hop) encryption.
- **I2P** uses **garlic routing** with unidirectional tunnels — separate inbound and outbound tunnels are required, and multiple message "cloves" are bundled into a single encrypted "garlic bulb" to obscure packet origin/destination.

These differing designs have direct implications for performance, which this study set out to measure empirically.

## Methodology

- **Test environment:** Two machines connected to the I2P network — one configured as a dedicated out-proxy, the other as a client using both dedicated and public out-proxies.
- **Measurement tooling:** Perl scripts (originally developed by Fabian et al. for prior Tor research) were used to automate HTTP-GET requests, full webpage loads, and incremental file downloads (50 KB–1 MB).
- **Test sample:** The 500 most popular websites, accessed alternately via direct connection, Tor, and I2P.
- **Metrics captured:**
  - **Core latency** — response time for a basic HTTP-GET request
  - **Average latency** — full page load time including images/external resources
  - **Bandwidth** — download speed across a range of file sizes

## Key Findings

| Metric | Tor | I2P |
|---|---|---|
| Core latency (avg) | 3.31 s | 10.07 s |
| Average latency (median) | 9.60–30.26 s (IQR) | ~103.19 s (median), up to 226.85 s (75th percentile) |
| Bandwidth (avg) | 937.90 kB/s | 31.28 kB/s |

- **Tor consistently outperformed I2P** across all three metrics, largely attributed to Tor's bidirectional tunnels and streamlined onion routing versus I2P's unidirectional tunnels and garlic routing overhead.
- **I2P's performance degraded significantly** for complex, multi-resource page loads and larger file transfers, partly due to limited out-proxy availability causing congestion.
- I2P remains well-suited to its intended use case — isolated, internal anonymous communication — but is less competitive for latency-sensitive or bandwidth-intensive external browsing tasks.

## Reproducing the Experiments

1. Set up two machines on the I2P network — one as a dedicated out-proxy, one as a client.
2. Configure a 2-hop I2P tunnel with standard parameters.
3. Run the Perl scripts (see `scripts/perl/`) to:
   - Send HTTP-GET requests to target URLs and record response times
   - Load full webpages and record total load time
   - Download files of increasing size (50 KB–1 MB) and record throughput
4. Repeat tests alternating between direct connection, Tor, and I2P for comparison.
5. Aggregate results and compute mean, median, and quartile statistics.

*(Include your actual scripts/data in the repo so this section reflects what's reproducible from the code you have.)*

## Future Work

- Scaling I2P out-proxy availability to reduce congestion
- Adaptive tunnel-length techniques in I2P to balance latency and anonymity
- Hybrid encryption/routing models combining onion and garlic routing strengths
- Machine-learning-based routing optimization for both networks
- Decentralized name resolution for I2P to improve usability

## References

1. Mack, J. D. (2003). *Network analysis, architecture, and design* (2nd ed.). Morgan Kaufmann.
2. Dingledine, R., Mathewson, N., & Syverson, P. (2004). *Tor: The Second-Generation Onion Router.* The Free Haven Project and Naval Research Lab.
3. Tor Project. (n.d.). *Key management.* Tor Project Support.
4. Astolfi, F., Kroese, J., & van Oorschot, J. (2015). *I2P – The Invisible Internet Project.* Leiden University.
5. The Invisible Internet Project. (n.d.). *Technical Introduction.*
6. Fabian, B., Goertz, F., Kunz, S., Müller, S., & Nitzsche, M. (2010). *Privately Waiting – A Usability Analysis of the Tor Anonymity Network.* AMCIS 2010 Proceedings.

## License

This research paper and accompanying materials were produced for academic purposes as part of a university research project.
