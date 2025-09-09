import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { useApi } from '../context/ApiContext';
import StatusCard from '../components/StatusCard';
import { RefreshCw, Activity, Users, Server, Globe } from 'lucide-react';

const Container = styled.div`
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
`;

const Header = styled.div`
  display: flex;
  justify-content: between;
  align-items: center;
  margin-bottom: 2rem;
`;

const Title = styled.h1`
  font-size: 2rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0;
`;

const RefreshButton = styled.button`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: #21262d;
  border: 1px solid #30363d;
  border-radius: 6px;
  color: #f0f6fc;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-left: auto;

  &:hover {
    background: #30363d;
    border-color: #58a6ff;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  svg {
    width: 16px;
    height: 16px;
    ${props => props.spinning ? 'animation: spin 1s linear infinite;' : ''}
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;

const Grid = styled.div`
  display: grid;
  gap: 1.5rem;
  margin-bottom: 2rem;

  @media (min-width: 768px) {
    grid-template-columns: 1fr 1fr;
  }
`;

const FullWidthCard = styled.div`
  grid-column: 1 / -1;
`;

const DetailSection = styled.div`
  background: #161b22;
  border: 1px solid #30363d;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
`;

const SectionTitle = styled.h3`
  font-size: 1.125rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0 0 1rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;

  svg {
    width: 20px;
    height: 20px;
  }
`;

const InfoGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
`;

const InfoItem = styled.div`
  display: flex;
  justify-content: between;
  align-items: center;
  padding: 0.75rem;
  background: #0d1117;
  border-radius: 4px;
  border: 1px solid #21262d;
`;

const InfoLabel = styled.span`
  font-size: 0.875rem;
  color: #7d8590;
  font-weight: 500;
`;

const InfoValue = styled.span`
  font-size: 0.875rem;
  font-weight: 600;
  color: #f0f6fc;
  margin-left: auto;
`;

const ErrorMessage = styled.div`
  background: #7f1d1d;
  border: 1px solid #f87171;
  border-radius: 6px;
  padding: 1rem;
  color: #fecaca;
  margin-bottom: 1rem;
`;

const LoadingSpinner = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 2rem;
  color: #7d8590;

  svg {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;

const PeersList = styled.div`
  max-height: 300px;
  overflow-y: auto;
  margin-top: 1rem;
`;

const PeerItem = styled.div`
  display: flex;
  justify-content: between;
  align-items: center;
  padding: 0.75rem;
  background: #0d1117;
  border: 1px solid #21262d;
  border-radius: 4px;
  margin-bottom: 0.5rem;
`;

const PeerInfo = styled.div`
  flex: 1;
`;

const PeerAddress = styled.div`
  font-size: 0.875rem;
  font-weight: 500;
  color: #f0f6fc;
  margin-bottom: 0.25rem;
`;

const PeerDetails = styled.div`
  font-size: 0.75rem;
  color: #7d8590;
`;

const StatusBadge = styled.span`
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
  background: ${props => {
    switch(props.status) {
      case 'connected': return '#1a472a';
      case 'disconnected': return '#7f1d1d';
      default: return '#374151';
    }
  }};
  color: ${props => {
    switch(props.status) {
      case 'connected': return '#4ade80';
      case 'disconnected': return '#f87171';
      default: return '#9ca3af';
    }
  }};
`;

const NodeStatus = () => {
  const { 
    loading, 
    error,
    getNodeStatus,
    getNodePeers,
    checkHealth
  } = useApi();

  const [nodeData, setNodeData] = useState(null);
  const [peerData, setPeerData] = useState(null);
  const [healthData, setHealthData] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = async () => {
    setRefreshing(true);
    
    try {
      // Fetch node status
      const node = await getNodeStatus();
      setNodeData(node);

      // Fetch health data
      const health = await checkHealth();
      setHealthData(health);

      // Fetch peer data
      const peers = await getNodePeers();
      setPeerData(peers);
    } catch (err) {
      console.error('Failed to fetch node data:', err);
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
    
    // Auto refresh every 15 seconds
    const interval = setInterval(fetchData, 15000);
    return () => clearInterval(interval);
  }, []);

  const formatTimestamp = (timestamp) => {
    if (!timestamp) return 'N/A';
    return new Date(timestamp).toLocaleString();
  };

  const formatUptime = (timestamp) => {
    if (!timestamp) return 'N/A';
    const diff = Date.now() - new Date(timestamp).getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}h ${minutes}m`;
  };

  if (loading && !nodeData) {
    return (
      <Container>
        <LoadingSpinner>
          <RefreshCw size={24} />
          <span style={{ marginLeft: '0.5rem' }}>Loading node status...</span>
        </LoadingSpinner>
      </Container>
    );
  }

  return (
    <Container>
      <Header>
        <Title>Node Status</Title>
        <RefreshButton 
          onClick={fetchData} 
          disabled={refreshing}
          spinning={refreshing}
        >
          <RefreshCw />
          {refreshing ? 'Refreshing...' : 'Refresh'}
        </RefreshButton>
      </Header>

      {error && (
        <ErrorMessage>
          Error: {error}
        </ErrorMessage>
      )}

      <Grid>
        <StatusCard
          title="Node Health"
          status={nodeData?.details?.catching_up ? 'syncing' : 'synced'}
          description="Current blockchain synchronization status"
          metrics={[
            { label: 'Block Height', value: nodeData?.details?.latest_block_height || '0' },
            { label: 'Catching Up', value: nodeData?.details?.catching_up ? 'Yes' : 'No' },
            { label: 'Last Block', value: formatTimestamp(nodeData?.details?.latest_block_time) },
            { label: 'Network', value: nodeData?.details?.network || 'unknown' }
          ]}
        />

        <StatusCard
          title="System Health"
          status={healthData?.status}
          description="Overall system component health"
          metrics={[
            { label: 'LLM Server', value: healthData?.components?.llm_server || 'unknown' },
            { label: 'Blockchain Node', value: healthData?.components?.blockchain_node || 'unknown' },
            { label: 'Last Check', value: formatTimestamp(healthData?.timestamp) },
            { label: 'Response Time', value: '< 100ms' }
          ]}
        />
      </Grid>

      <DetailSection>
        <SectionTitle>
          <Server />
          Node Information
        </SectionTitle>
        <InfoGrid>
          <InfoItem>
            <InfoLabel>Node ID</InfoLabel>
            <InfoValue>{nodeData?.details?.node_id?.slice(0, 16) + '...' || 'N/A'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Moniker</InfoLabel>
            <InfoValue>{nodeData?.details?.moniker || 'N/A'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Version</InfoLabel>
            <InfoValue>{nodeData?.details?.version || 'N/A'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Network</InfoLabel>
            <InfoValue>{nodeData?.details?.network || 'N/A'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Latest Block Height</InfoLabel>
            <InfoValue>{nodeData?.details?.latest_block_height || '0'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Latest Block Time</InfoLabel>
            <InfoValue>{formatTimestamp(nodeData?.details?.latest_block_time)}</InfoValue>
          </InfoItem>
        </InfoGrid>
      </DetailSection>

      <DetailSection>
        <SectionTitle>
          <Users />
          Peer Connectivity ({peerData?.total_peers || 0} peers)
        </SectionTitle>
        
        <InfoGrid style={{ marginBottom: '1rem' }}>
          <InfoItem>
            <InfoLabel>Total Peers</InfoLabel>
            <InfoValue>{peerData?.total_peers || 0}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Listening</InfoLabel>
            <InfoValue>{peerData?.listening ? 'Yes' : 'No'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Connectivity Health</InfoLabel>
            <InfoValue>{peerData?.peer_analysis?.connectivity_health || 'unknown'}</InfoValue>
          </InfoItem>
          <InfoItem>
            <InfoLabel>Peer Diversity</InfoLabel>
            <InfoValue>{peerData?.peer_analysis?.peer_diversity || 'unknown'}</InfoValue>
          </InfoItem>
        </InfoGrid>

        {peerData?.peers_sample && peerData.peers_sample.length > 0 && (
          <PeersList>
            <h4 style={{ color: '#f0f6fc', marginBottom: '0.5rem', fontSize: '0.875rem' }}>
              Sample Peers
            </h4>
            {peerData.peers_sample.map((peer, index) => (
              <PeerItem key={index}>
                <PeerInfo>
                  <PeerAddress>
                    {peer.node_info?.id?.slice(0, 16)}...@{peer.remote_ip}
                  </PeerAddress>
                  <PeerDetails>
                    Moniker: {peer.node_info?.moniker || 'Unknown'} | 
                    Network: {peer.node_info?.network || 'Unknown'}
                  </PeerDetails>
                </PeerInfo>
                <StatusBadge status={peer.is_outbound ? 'connected' : 'connected'}>
                  {peer.is_outbound ? 'Outbound' : 'Inbound'}
                </StatusBadge>
              </PeerItem>
            ))}
          </PeersList>
        )}
      </DetailSection>
    </Container>
  );
};

export default NodeStatus;