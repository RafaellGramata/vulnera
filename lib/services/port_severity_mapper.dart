class PortFinding {
  final String title;
  final String description;
  final String severity;
  final double cvssScore;

  PortFinding({
    required this.title,
    required this.description,
    required this.severity,
    required this.cvssScore,
  });
}

class PortSeverityMapper {
  // maps a known port number to a security finding - based on how
  // risky it is for that service to be exposed and reachable at all,
  // not on any specific vulnerability in a specific software version
  // (we don't have banner/version data, just "this port is open")
  static PortFinding findingForPort(int port) {
    switch (port) {
      case 21:
        return PortFinding(
          title: 'FTP Port Open (21)',
          description: 'FTP is open on this device. Traditional FTP transmits credentials and data in plaintext, making it easy to intercept on a shared network.',
          severity: 'Medium',
          cvssScore: 5.9,
        );
      case 22:
        return PortFinding(
          title: 'SSH Port Open (22)',
          description: 'SSH is open on this device. This is expected for servers managed remotely, but should be reviewed to confirm it is intentional and password-based login is disabled in favor of key-based authentication.',
          severity: 'Low',
          cvssScore: 3.1,
        );
      case 23:
        return PortFinding(
          title: 'Telnet Port Open (23)',
          description: 'Telnet is open on this device. Telnet transmits all data, including credentials, in plaintext with no encryption. This is a legacy, insecure protocol that should generally be disabled.',
          severity: 'High',
          cvssScore: 7.4,
        );
      case 80:
        return PortFinding(
          title: 'Unencrypted HTTP Open (80)',
          description: 'A web server is reachable over plain HTTP. If this device serves anything sensitive, traffic could be intercepted on a shared network.',
          severity: 'Low',
          cvssScore: 3.7,
        );
      case 443:
        return PortFinding(
          title: 'HTTPS Port Open (443)',
          description: 'A web server is reachable over HTTPS. This is expected for most devices; flagged here only for visibility in the asset inventory.',
          severity: 'Low',
          cvssScore: 2.0,
        );
      case 445:
        return PortFinding(
          title: 'SMB File Sharing Open (445)',
          description: 'SMB (file sharing) is open and reachable. This service has a history of serious remote exploits (e.g. EternalBlue/WannaCry) when left exposed, especially to untrusted networks.',
          severity: 'High',
          cvssScore: 8.1,
        );
      case 3389:
        return PortFinding(
          title: 'Remote Desktop Open (3389)',
          description: 'RDP is open and reachable. Exposed RDP is a common target for brute-force attacks and ransomware entry. Should be restricted to trusted networks or disabled if not actively used.',
          severity: 'Critical',
          cvssScore: 9.1,
        );
      default:
        return PortFinding(
          title: 'Open Port Detected ($port)',
          description: 'An unrecognized service is reachable on port $port. Review whether this is expected and necessary.',
          severity: 'Low',
          cvssScore: 3.0,
        );
    }
  }
}