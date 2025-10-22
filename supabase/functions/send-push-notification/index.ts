// Supabase Edge Function to send push notifications via OneSignal
// Deploy this to: https://kyjnimuwkfrwcdbdgcyz.supabase.co/functions/v1/send-push-notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const ONESIGNAL_API_URL = "https://onesignal.com/api/v1/notifications"

interface NotificationPayload {
  notification_id: string
  recipient_id: string
  title: string
  body: string
  data?: Record<string, any>
}

serve(async (req) => {
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // Get environment variables
    const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')
    const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      console.error('Missing OneSignal environment variables')
      return new Response('Server configuration error', { status: 500 })
    }

    // Parse request body
    const payload: NotificationPayload = await req.json()
    
    if (!payload.recipient_id || !payload.title || !payload.body) {
      return new Response('Missing required fields', { status: 400 })
    }

    // Build OneSignal notification payload
    const oneSignalPayload = {
      app_id: ONESIGNAL_APP_ID,
      include_external_user_ids: [payload.recipient_id],
      headings: { en: payload.title },
      contents: { en: payload.body },
      data: payload.data || {},
      // Optional: Add custom sound, badge, etc.
      // ios_sound: "default",
      // android_sound: "default",
    }

    console.log('Sending OneSignal notification to:', payload.recipient_id)
    
    // Send to OneSignal
    const response = await fetch(ONESIGNAL_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(oneSignalPayload),
    })

    const responseText = await response.text()
    
    if (!response.ok) {
      console.error('OneSignal API error:', response.status, responseText)
      return new Response('Failed to send notification', { status: 500 })
    }

    console.log('OneSignal notification sent successfully:', responseText)
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Notification sent successfully',
        onesignal_response: JSON.parse(responseText)
      }),
      { 
        headers: { 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error in send-push-notification function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        headers: { 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

/* 
Deployment instructions:

1. Install Supabase CLI: npm install -g supabase
2. Login: supabase login
3. Link your project: supabase link --project-ref YOUR_PROJECT_ID
4. Create this function: supabase functions new send-push-notification
5. Replace the generated index.ts with this code
6. Set environment variables:
   supabase secrets set ONESIGNAL_APP_ID=your_app_id
   supabase secrets set ONESIGNAL_REST_API_KEY=your_rest_api_key
7. Deploy: supabase functions deploy send-push-notification

To test locally:
supabase functions serve send-push-notification --env-file supabase/.env.local

Create supabase/.env.local with:
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_rest_api_key
