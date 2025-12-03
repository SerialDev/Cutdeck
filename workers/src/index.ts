/**
 * Cutdeck Workers Entry Point
 * 
 * This Worker handles routing for the Cutdeck application:
 * - Static frontend assets are served from Cloudflare Pages
 * - API requests are routed to the Backend Container (Python + DaggyD)
 * - Database queries use D1
 * - Image storage uses Workers KV
 */

import { Container, getContainer } from '@cloudflare/containers';

// =============================================================================
// Type Definitions
// =============================================================================

interface Env {
  BACKEND_CONTAINER: DurableObjectNamespace;
  // Uncomment when configured:
  // DB: D1Database;
  // IMAGES: KVNamespace;
  ENVIRONMENT: string;
}

// =============================================================================
// Backend Container Configuration
// =============================================================================

/**
 * BackendContainer wraps the Python FastAPI + DaggyD backend.
 * It runs on Cloudflare's edge network as a serverless container.
 */
export class BackendContainer extends Container {
  // Port the FastAPI server listens on
  defaultPort = 8000;
  
  // Stop container after 10 minutes of inactivity
  sleepAfter = '10m';
  
  // Environment variables passed to the container
  envVars = {
    PYTHONUNBUFFERED: '1',
    ENVIRONMENT: 'production',
  };

  override onStart(): void {
    console.log('[BackendContainer] Container started successfully');
  }

  override onStop(): void {
    console.log('[BackendContainer] Container stopped');
  }

  override onError(error: unknown): void {
    console.error('[BackendContainer] Container error:', error);
  }
}

// =============================================================================
// Request Handler
// =============================================================================

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const pathname = url.pathname;

    // CORS headers for API requests
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // =========================================================================
      // API Routes - Forward to Backend Container
      // =========================================================================
      if (pathname.startsWith('/api/')) {
        // Get or create a backend container instance
        // Using 'default' as the session ID for stateless API calls
        // For stateful sessions, use a unique session ID
        const container = getContainer(env.BACKEND_CONTAINER, 'default');
        
        // Rewrite the path to remove /api prefix
        const backendUrl = new URL(request.url);
        backendUrl.pathname = pathname.replace('/api', '');
        
        const backendRequest = new Request(backendUrl.toString(), request);
        const response = await container.fetch(backendRequest);
        
        // Add CORS headers to response
        const newHeaders = new Headers(response.headers);
        Object.entries(corsHeaders).forEach(([key, value]) => {
          newHeaders.set(key, value);
        });
        
        return new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders,
        });
      }

      // =========================================================================
      // Health Check
      // =========================================================================
      if (pathname === '/health' || pathname === '/_health') {
        return Response.json({
          status: 'healthy',
          service: 'cutdeck-worker',
          environment: env.ENVIRONMENT,
          timestamp: new Date().toISOString(),
        }, { headers: corsHeaders });
      }

      // =========================================================================
      // Container Status (for debugging)
      // =========================================================================
      if (pathname === '/_container/status') {
        const container = getContainer(env.BACKEND_CONTAINER, 'default');
        try {
          const healthResponse = await container.fetch(new Request('http://container/health'));
          const health = await healthResponse.json();
          return Response.json({
            container: 'running',
            backend: health,
          }, { headers: corsHeaders });
        } catch (error) {
          return Response.json({
            container: 'starting_or_error',
            error: String(error),
          }, { status: 503, headers: corsHeaders });
        }
      }

      // =========================================================================
      // Root - Return API info
      // =========================================================================
      if (pathname === '/') {
        return Response.json({
          name: 'Cutdeck API',
          version: '0.1.0',
          description: 'Cutdeck backend running on Cloudflare Containers',
          endpoints: {
            health: '/health',
            api: '/api/*',
            containerStatus: '/_container/status',
          },
          docs: '/api/docs',
        }, { headers: corsHeaders });
      }

      // =========================================================================
      // 404 - Not Found
      // =========================================================================
      return Response.json({
        error: 'Not Found',
        path: pathname,
      }, { status: 404, headers: corsHeaders });

    } catch (error) {
      console.error('Worker error:', error);
      return Response.json({
        error: 'Internal Server Error',
        message: error instanceof Error ? error.message : 'Unknown error',
      }, { status: 500, headers: corsHeaders });
    }
  },
};
