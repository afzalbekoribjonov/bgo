import TabNav from './tab-nav';

export default function RestaurantLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { id: string };
}) {
  return (
    <>
      <TabNav id={params.id} />
      {children}
    </>
  );
}
