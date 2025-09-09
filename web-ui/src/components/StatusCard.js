import React from 'react';
import styled from 'styled-components';
import { CheckCircle, AlertCircle, XCircle, Clock } from 'lucide-react';

const Card = styled.div`
  background: #161b22;
  border: 1px solid #30363d;
  border-radius: 8px;
  padding: 1.5rem;
  transition: border-color 0.2s ease;

  &:hover {
    border-color: #58a6ff;
  }
`;

const Header = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
`;

const Title = styled.h3`
  font-size: 1.125rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0;
`;

const StatusBadge = styled.div`
  display: flex;
  align-items: center;
  padding: 0.375rem 0.75rem;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  background: ${props => {
    switch(props.status) {
      case 'ok':
      case 'healthy':
      case 'synced': return '#1a472a';
      case 'warning':
      case 'syncing': return '#7c2d12';
      case 'error':
      case 'down':
      case 'offline': return '#7f1d1d';
      default: return '#374151';
    }
  }};
  color: ${props => {
    switch(props.status) {
      case 'ok':
      case 'healthy':
      case 'synced': return '#4ade80';
      case 'warning':
      case 'syncing': return '#fbbf24';
      case 'error':
      case 'down':
      case 'offline': return '#f87171';
      default: return '#9ca3af';
    }
  }};

  svg {
    width: 16px;
    height: 16px;
    margin-right: 0.375rem;
  }
`;

const Content = styled.div`
  color: #8b949e;
  line-height: 1.5;
`;

const MetricsList = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-top: 1rem;
`;

const Metric = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem;
  background: #0d1117;
  border-radius: 4px;
  border: 1px solid #21262d;
`;

const MetricLabel = styled.span`
  font-size: 0.875rem;
  color: #7d8590;
`;

const MetricValue = styled.span`
  font-size: 0.875rem;
  font-weight: 600;
  color: #f0f6fc;
`;

const getStatusIcon = (status) => {
  switch(status) {
    case 'ok':
    case 'healthy':
    case 'synced':
      return <CheckCircle />;
    case 'warning':
    case 'syncing':
      return <AlertCircle />;
    case 'error':
    case 'down':
    case 'offline':
      return <XCircle />;
    default:
      return <Clock />;
  }
};

const StatusCard = ({ 
  title, 
  status, 
  description, 
  metrics = [], 
  children,
  loading = false 
}) => {
  return (
    <Card>
      <Header>
        <Title>{title}</Title>
        <StatusBadge status={loading ? 'loading' : status}>
          {getStatusIcon(loading ? 'loading' : status)}
          {loading ? 'Loading...' : status || 'Unknown'}
        </StatusBadge>
      </Header>
      
      {description && <Content>{description}</Content>}
      
      {metrics.length > 0 && (
        <MetricsList>
          {metrics.map(({ label, value }, index) => (
            <Metric key={index}>
              <MetricLabel>{label}</MetricLabel>
              <MetricValue>{value}</MetricValue>
            </Metric>
          ))}
        </MetricsList>
      )}
      
      {children}
    </Card>
  );
};

export default StatusCard;