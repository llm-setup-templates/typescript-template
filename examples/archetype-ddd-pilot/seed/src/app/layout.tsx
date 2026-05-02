import './globals.css';
import { OrderProvider } from './providers/order.context';

export const metadata = {
  title: '{{PROJECT_NAME}}',
  description: 'archetype-ddd-pilot demo',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">
        <OrderProvider>{children}</OrderProvider>
      </body>
    </html>
  );
}
