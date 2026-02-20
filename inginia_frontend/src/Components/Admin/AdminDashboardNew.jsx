import React, { useEffect, useState } from "react";
import axios from "../../axios";
import { useNavigate } from "react-router-dom";
import {
  FaUsers,
  FaClipboardList,
  FaMoneyBillWave,
  FaStar,
  FaArrowUp,
  FaArrowDown,
  FaFilter,
  FaDownload,
  FaExclamationTriangle,
  FaUserCheck,
  FaBuilding,
} from "react-icons/fa";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, Cell, PieChart, Pie
} from 'recharts';

const AdminDashboardNew = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState('month'); // day, week, month, year

  useEffect(() => {
    loadStats();
    
    // Auto refresh every 5 minutes
    const interval = setInterval(() => {
      loadStats();
    }, 5 * 60 * 1000);

    return () => clearInterval(interval);
  }, [period]);

  const loadStats = async () => {
    setLoading(true);
    try {
      const response = await axios.get(`/admin/dashboard/stats?period=${period}`);
      setStats(response.data);
    } catch (error) {
      console.error("Erreur chargement stats:", error);
    } finally {
      setLoading(false);
    }
  };

  const exportData = () => {
    if (!stats) return;
    
    const rows = [
      ["Metric", "Value", "Variation"],
      ["Users", stats.kpi.users.total, `${stats.kpi.users.variation}%`],
      ["Missions", stats.kpi.missions.total, `${stats.kpi.missions.variation}%`],
      ["Revenue", stats.kpi.revenue.total, `${stats.kpi.revenue.variation}%`],
      ["Avg Rating", stats.kpi.rating.average, `${stats.kpi.rating.variation}%`],
    ];

    let csvContent = "data:text/csv;charset=utf-8," 
        + rows.map(e => e.join(",")).join("\n");
    
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `dashboard_stats_${period}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const kpiCards = [
    {
      title: "Utilisateurs",
      value: stats?.kpi?.users?.total || 0,
      variation: stats?.kpi?.users?.variation || 0,
      icon: FaUsers,
      color: "blue",
      subValue: `${stats?.total_clients || 0} Clients / ${stats?.total_providers || 0} Pros`,
    },
    {
      title: "Missions",
      value: stats?.kpi?.missions?.total || 0,
      variation: stats?.kpi?.missions?.variation || 0,
      icon: FaClipboardList,
      color: "emerald",
      subValue: "Total réservations",
    },
    {
      title: "Chiffre d'Affaires",
      value: `${stats?.kpi?.revenue?.total?.toLocaleString()} FCFA`,
      variation: stats?.kpi?.revenue?.variation || 0,
      icon: FaMoneyBillWave,
      color: "amber",
      subValue: "Commissions plateforme",
    },
    {
      title: "Note Moyenne",
      value: stats?.kpi?.rating?.average || "0.0",
      variation: stats?.kpi?.rating?.variation || 0,
      icon: FaStar,
      color: "purple",
      subValue: "Sur tous les avis",
    },
  ];

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8', '#82ca9d'];

  return (
    <div className="space-y-8 animate-fadeIn pb-20">
      
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
        <div>
          <h1 className="text-3xl font-black text-slate-800">Tableau de Bord</h1>
          <p className="text-slate-500">Vue d'ensemble des performances</p>
        </div>
        
        <div className="flex gap-3">
          {/* Period Filter */}
          <div className="flex bg-slate-100 p-1 rounded-xl">
            {['day', 'week', 'month', 'year'].map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
                  period === p 
                    ? 'bg-white text-blue-600 shadow-sm' 
                    : 'text-slate-500 hover:text-slate-700'
                }`}
              >
                {p === 'day' ? 'Jour' : p === 'week' ? 'Semaine' : p === 'month' ? 'Mois' : 'Année'}
              </button>
            ))}
          </div>

          <button 
            onClick={exportData}
            className="flex items-center gap-2 px-4 py-2 bg-slate-800 text-white rounded-xl font-bold text-sm hover:bg-slate-700 transition-all"
          >
            <FaDownload /> Export
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {kpiCards.map((kpi, index) => (
          <div key={index} className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className={`w-12 h-12 rounded-2xl bg-${kpi.color}-50 text-${kpi.color}-500 flex items-center justify-center text-xl`}>
                <kpi.icon />
              </div>
              <div className={`flex items-center gap-1 text-sm font-bold ${
                kpi.variation >= 0 ? 'text-emerald-500' : 'text-rose-500'
              }`}>
                {kpi.variation >= 0 ? <FaArrowUp size={10} /> : <FaArrowDown size={10} />}
                {Math.abs(kpi.variation)}%
              </div>
            </div>
            <h3 className="text-3xl font-black text-slate-800 mb-1">{kpi.value}</h3>
            <p className="text-sm text-slate-400 font-medium uppercase tracking-wide">{kpi.title}</p>
            <p className="text-xs text-slate-300 mt-2">{kpi.subValue}</p>
          </div>
        ))}
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Revenue Chart */}
          <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
              <h2 className="text-xl font-black text-slate-800 mb-6 flex items-center gap-2">
                <FaMoneyBillWave className="text-amber-500" /> 
                Revenus (Commissions)
              </h2>
              <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={stats?.charts?.revenue || []}>
                          <defs>
                              <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                  <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.1}/>
                                  <stop offset="95%" stopColor="#f59e0b" stopOpacity={0}/>
                              </linearGradient>
                          </defs>
                          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                          <XAxis 
                            dataKey="date" 
                            axisLine={false} 
                            tickLine={false} 
                            tick={{fill: '#94a3b8', fontSize: 12}}
                            tickFormatter={(val) => {
                              try {
                                const d = new Date(val);
                                return `${d.getDate()}/${d.getMonth()+1}`;
                              } catch(e) { return val; }
                            }}
                          />
                          <YAxis 
                            axisLine={false} 
                            tickLine={false} 
                            tick={{fill: '#94a3b8', fontSize: 12}}
                          />
                          <Tooltip 
                            contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}
                          />
                          <Area 
                            type="monotone" 
                            dataKey="total" 
                            stroke="#f59e0b" 
                            strokeWidth={3}
                            fillOpacity={1} 
                            fill="url(#colorRevenue)" 
                          />
                      </AreaChart>
                  </ResponsiveContainer>
              </div>
          </div>

          {/* Users Growth Chart (Curve) */}
          <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
              <h2 className="text-xl font-black text-slate-800 mb-6 flex items-center gap-2">
                <FaUsers className="text-blue-500" /> 
                Croissance Utilisateurs
              </h2>
              <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={stats?.charts?.users_active || []}>
                          <defs>
                              <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1}/>
                                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                              </linearGradient>
                          </defs>
                          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                          <XAxis 
                            dataKey="date" 
                            axisLine={false} 
                            tickLine={false} 
                            tick={{fill: '#94a3b8', fontSize: 12}}
                            tickFormatter={(val) => {
                              try {
                                const d = new Date(val);
                                return `${d.getDate()}/${d.getMonth()+1}`;
                              } catch(e) { return val; }
                            }}
                          />
                          <YAxis 
                            axisLine={false} 
                            tickLine={false} 
                            tick={{fill: '#94a3b8', fontSize: 12}}
                          />
                          <Tooltip 
                            contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}
                          />
                          <Area 
                            type="monotone" 
                            dataKey="count" 
                            stroke="#3b82f6" 
                            strokeWidth={3}
                            fillOpacity={1} 
                            fill="url(#colorUsers)" 
                          />
                      </AreaChart>
                  </ResponsiveContainer>
              </div>
          </div>
      </div>

      {/* Row 2: Missions Pie Chart & Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Missions Breakdown (2/3) */}
          <div className="lg:col-span-2 bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
            <h2 className="text-xl font-black text-slate-800 mb-6 flex items-center gap-2">
              <FaClipboardList className="text-emerald-500" />
              Répartition des Missions
            </h2>
            <div className="h-64 w-full flex items-center justify-center">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                      <Pie
                        data={stats?.charts?.missions_by_category || []}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={5}
                        dataKey="value"
                        label={({name, percent}) => `${name} ${(percent * 100).toFixed(0)}%`}
                      >
                        {(stats?.charts?.missions_by_category || []).map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                </ResponsiveContainer>
            </div>
            
            {/* Legend for Pie Chart */}
            <div className="flex flex-wrap gap-4 justify-center mt-4">
               {(stats?.charts?.missions_by_category || []).slice(0, 6).map((item, idx) => (
                  <div key={idx} className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full" style={{backgroundColor: COLORS[idx % COLORS.length]}}></div>
                    <span className="font-bold text-slate-600">{item.name}: {item.value}</span>
                  </div>
               ))}
            </div>
          </div>

          {/* Alerts Zone (1/3) */}
          <div className="bg-rose-50 p-6 rounded-3xl border border-rose-100 flex flex-col h-full">
            <h2 className="text-xl font-black text-rose-800 mb-6 flex items-center gap-2">
              <FaExclamationTriangle />
              Alertes
            </h2>
            
            <div className="space-y-4 flex-1">
              <div 
                onClick={() => navigate('/admin/providers/validation')}
                className="bg-white p-4 rounded-2xl shadow-sm flex items-center gap-4 cursor-pointer hover:scale-105 transition-transform"
              >
                <div className="w-12 h-12 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center font-bold text-lg">
                  {stats?.alerts?.pending_providers || 0}
                </div>
                <div>
                  <h4 className="font-bold text-slate-800">Validations</h4>
                  <p className="text-xs text-slate-500">Demandes en attente</p>
                </div>
              </div>

              <div className="bg-white p-4 rounded-2xl shadow-sm flex items-center gap-4 cursor-pointer hover:scale-105 transition-transform">
                <div className="w-12 h-12 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center font-bold text-lg">
                  {stats?.alerts?.pending_reports || 0}
                </div>
                <div>
                  <h4 className="font-bold text-slate-800">Litiges</h4>
                  <p className="text-xs text-slate-500">Réclamations actives</p>
                </div>
              </div>
            </div>

            {/* Quick Summary */}
            <div className="mt-8 pt-6 border-t border-rose-200">
               <div className="flex justify-between items-center mb-2">
                 <span className="text-rose-800 text-sm font-bold">Total Prestataires</span>
                 <span className="text-rose-800 font-black">{stats?.total_providers || 0}</span>
               </div>
               <div className="w-full bg-rose-200 h-2 rounded-full overflow-hidden">
                 <div 
                   className="bg-rose-500 h-full rounded-full" 
                   style={{width: `${(stats?.validated_providers / (stats?.total_providers || 1)) * 100}%`}}
                 ></div>
               </div>
               <p className="text-xs text-rose-600 mt-1 text-right">
                 {Math.round((stats?.validated_providers / (stats?.total_providers || 1)) * 100)}% validés
               </p>
            </div>
          </div>
      </div>

    </div>
  );
};

export default AdminDashboardNew;
