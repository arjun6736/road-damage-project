// assets
import { DashboardOutlined } from '@ant-design/icons';

// icons
const icons = {
  DashboardOutlined
};

// ==============================|| MENU ITEMS - DASHBOARD ||============================== //

const dashboard = {
  id: 'group-dashboard',
  title: 'Navigation',
  type: 'group',
  children: [
    {
      id: 'dashboard',
      title: 'Dashboard',
      type: 'item',
      url: '/dashboard/default',
      icon: icons.DashboardOutlined,
      breadcrumbs: false
    },
    {
      id: 'reports',
      title: 'Reports',
      type: 'item',
      url: '/reportstable',
      breadcrumbs: false
    },
    {
      id: 'map',
      title: 'Map View',
      type: 'item',
      url: '/map',
      breadcrumbs: false
    }
  ]
};

export default dashboard;
