import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { useAuth } from "./Components/Context/AuthContext";
import Spinner from "./Components/Common/Spinner";
import DashboardLayout from "./Components/Layouts/DashboardLayout";

import Home from "./Components/Home/Home";
import Contacts from "./Components/Footer/Contact";
import NotreEquipe from "./Components/Footer/NotreEquipe";
import FAQ from "./Components/Footer/FAQ";
import ProfileSettings from "./Components/Parametrages/ProfileSettings";

import Login from "./Components/Auth/Login";
import Register from "./Components/Auth/Register";
import PrivateRoute from "./Components/PrivateRoute";

import AdminDashboard from "./Components/AdminDashboard";
import ProviderDashboard from "./Components/Providers/ProviderDashboard";
import ProviderProfile from "./Components/Providers/ProviderProfile";
import ClientDashboard from "./Components/Clients/ClientDashboard";
import SearchResults from "./Components/Home/SearchResults";

import Footer from "./Components/Footer";

const AppRoutes = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="h-screen flex items-center justify-center">
        <Spinner size={6} />
      </div>
    );
  }

  return (
    <Router>
      <Routes>
        {/* Routes publiques sans layout */}

        {/* Routes avec Navbar + Sidebar (DashboardLayout) */}
        <Route element={<DashboardLayout />}>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/contact" element={<Contacts />} />
          <Route path="/equipe" element={<NotreEquipe />} />
          <Route path="/faq" element={<FAQ />} />
          <Route path="/search" element={<SearchResults />} />
          <Route path="/" element={<Home />} />
          {/* Admin */}
          {/* Admin */}
          <Route
            path="/admin"
            element={
              <PrivateRoute role="admin">
                <AdminDashboard />
              </PrivateRoute>
            }
          />

          {/* Prestataire */}
          <Route
            path="/providerdashboard"
            element={
              <PrivateRoute role="prestataire">
                <ProviderDashboard />
              </PrivateRoute>
            }
          />

          {/* Client */}
          <Route
            path="/clientdashboard"
            element={
              <PrivateRoute role="client">
                <ClientDashboard />
              </PrivateRoute>
            }
          />
          <Route
            path="/provider/:id"
            element={
              <PrivateRoute>
                <ProviderProfile />
              </PrivateRoute>
            }
          />

          {/* Paramètres */}
          <Route
            path="/parametres/profile"
            element={
              <PrivateRoute>
                <ProfileSettings />
              </PrivateRoute>
            }
          />

          {/* <Route path="/parametres/security" element={<SecuritySettings />} /> */}

          {/* <Route path="/parametres/security" element={<SecuritySettings />} /> */}
          {/* <Route path="/parametres/preferences" element={<PreferencesSettings />} /> */}
          {/* <Route path="/parametres/notifications" element={<NotificationsSettings />} /> */}
        </Route>
      </Routes>

      <Footer />
    </Router>
  );
};

export default AppRoutes;
