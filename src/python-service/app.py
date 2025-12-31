"""
Ledger Audit Service - Python Microservice
A lightweight audit logging service for the Ledger platform.
"""

import os
import json
import logging
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
PORT = int(os.environ.get('PORT', 8081))
VERSION = os.environ.get('VERSION', '1.0.0')


class AuditHandler(BaseHTTPRequestHandler):
    """HTTP request handler for audit service endpoints."""

    def _send_json_response(self, status: int, data: Dict[str, Any]) -> None:
        """Send a JSON response with proper headers."""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_GET(self) -> None:
        """Handle GET requests."""
        if self.path == '/health':
            self._send_json_response(200, {
                'status': 'healthy',
                'timestamp': datetime.utcnow().isoformat()
            })
        elif self.path == '/version':
            self._send_json_response(200, {
                'version': VERSION,
                'service': 'audit-service',
                'language': 'python'
            })
        elif self.path == '/ready':
            self._send_json_response(200, {
                'ready': True,
                'checks': {
                    'database': 'ok',
                    'queue': 'ok'
                }
            })
        else:
            self._send_json_response(404, {'error': 'Not found'})

    def do_POST(self) -> None:
        """Handle POST requests for audit logging."""
        if self.path == '/audit':
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                audit_event = json.loads(body.decode('utf-8'))

                # Validate required fields
                required_fields = ['action', 'actor', 'resource']
                missing = [f for f in required_fields if f not in audit_event]

                if missing:
                    self._send_json_response(400, {
                        'error': 'Missing required fields',
                        'missing': missing
                    })
                    return

                # Add metadata
                audit_event['timestamp'] = datetime.utcnow().isoformat()
                audit_event['id'] = f"audit-{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}"

                # Log the audit event (in production, would persist to DB)
                logger.info(f"Audit event: {json.dumps(audit_event)}")

                self._send_json_response(201, {
                    'status': 'recorded',
                    'audit_id': audit_event['id']
                })

            except json.JSONDecodeError:
                self._send_json_response(400, {'error': 'Invalid JSON'})
        else:
            self._send_json_response(404, {'error': 'Not found'})

    def log_message(self, format: str, *args) -> None:
        """Override to use Python logging."""
        logger.info("%s - %s", self.address_string(), format % args)


def main() -> None:
    """Start the audit service."""
    server = HTTPServer(('0.0.0.0', PORT), AuditHandler)
    logger.info(f"Audit service v{VERSION} starting on port {PORT}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down audit service")
        server.shutdown()


if __name__ == '__main__':
    main()
