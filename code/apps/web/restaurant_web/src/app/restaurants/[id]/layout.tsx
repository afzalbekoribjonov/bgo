import { RestaurantProvider } from './restaurant-provider';
import PanelHeader from './panel-header';
import TabNav from './tab-nav';
import OfflineBar from '@/components/offline-bar';

export default function RestaurantLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { id: string };
}) {
  return (
    <RestaurantProvider id={params.id}>
      <PanelHeader />
      <TabNav id={params.id} />
      {children}
      <OfflineBar />
    </RestaurantProvider>
  );
}
