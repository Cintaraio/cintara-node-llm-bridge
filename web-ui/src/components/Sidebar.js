import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import styled from 'styled-components';
import { Activity, MessageCircle, Settings, Search, BarChart3, FileText } from 'lucide-react';

const SidebarContainer = styled.div`
  width: 250px;
  background: #161b22;
  border-right: 1px solid #30363d;
  display: flex;
  flex-direction: column;
  padding: 1rem 0;
`;

const Logo = styled.div`
  padding: 0 1rem 2rem 1rem;
  border-bottom: 1px solid #30363d;
  margin-bottom: 1rem;
`;

const LogoTitle = styled.h1`
  font-size: 1.25rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0;
`;

const LogoSubtitle = styled.p`
  font-size: 0.875rem;
  color: #7d8590;
  margin: 0.25rem 0 0 0;
`;

const NavList = styled.ul`
  list-style: none;
  padding: 0;
  margin: 0;
`;

const NavItem = styled.li`
  margin: 0.25rem 0;
`;

const NavLink = styled(Link)`
  display: flex;
  align-items: center;
  padding: 0.75rem 1rem;
  color: ${props => props.active ? '#f0f6fc' : '#8b949e'};
  text-decoration: none;
  background: ${props => props.active ? '#21262d' : 'transparent'};
  border-right: ${props => props.active ? '3px solid #1f6feb' : '3px solid transparent'};
  transition: all 0.2s ease;

  &:hover {
    background: #21262d;
    color: #f0f6fc;
  }

  svg {
    margin-right: 0.75rem;
    width: 18px;
    height: 18px;
  }
`;

const StatusIndicator = styled.div`
  margin-top: auto;
  padding: 1rem;
  border-top: 1px solid #30363d;
`;

const StatusItem = styled.div`
  display: flex;
  align-items: center;
  font-size: 0.875rem;
  margin: 0.5rem 0;
  color: #7d8590;
`;

const StatusDot = styled.div`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: ${props => {
    switch(props.status) {
      case 'online': return '#3fb950';
      case 'warning': return '#f85149';
      case 'offline': return '#f85149';
      default: return '#7d8590';
    }
  }};
  margin-right: 0.5rem;
`;

const Sidebar = () => {
  const location = useLocation();
  
  const navItems = [
    { path: '/', label: 'Dashboard', icon: BarChart3 },
    { path: '/status', label: 'Node Status', icon: Activity },
    { path: '/chat', label: 'AI Chat', icon: MessageCircle },
    { path: '/diagnostics', label: 'Diagnostics', icon: Search },
    { path: '/taxbit', label: 'TaxBit Export', icon: FileText },
  ];

  return (
    <SidebarContainer>
      <Logo>
        <LogoTitle>Cintara Node</LogoTitle>
        <LogoSubtitle>Management Console</LogoSubtitle>
      </Logo>
      
      <NavList>
        {navItems.map(({ path, label, icon: Icon }) => (
          <NavItem key={path}>
            <NavLink 
              to={path} 
              active={location.pathname === path ? 1 : 0}
            >
              <Icon />
              {label}
            </NavLink>
          </NavItem>
        ))}
      </NavList>

      <StatusIndicator>
        <StatusItem>
          <StatusDot status="online" />
          Bridge Connected
        </StatusItem>
        <StatusItem>
          <StatusDot status="online" />
          LLM Active
        </StatusItem>
        <StatusItem>
          <StatusDot status="warning" />
          Node Syncing
        </StatusItem>
      </StatusIndicator>
    </SidebarContainer>
  );
};

export default Sidebar;