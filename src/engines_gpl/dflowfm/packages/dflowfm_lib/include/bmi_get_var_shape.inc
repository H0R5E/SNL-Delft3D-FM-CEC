!----- AGPL --------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2015-2018.                                
!                                                                               
!  This file is part of Delft3D (D-Flow Flexible Mesh component).               
!                                                                               
!  Delft3D is free software: you can redistribute it and/or modify              
!  it under the terms of the GNU Affero General Public License as               
!  published by the Free Software Foundation version 3.                         
!                                                                               
!  Delft3D  is distributed in the hope that it will be useful,                  
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU Affero General Public License for more details.                          
!                                                                               
!  You should have received a copy of the GNU Affero General Public License     
!  along with Delft3D.  If not, see <http://www.gnu.org/licenses/>.             
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D",                  
!  "D-Flow Flexible Mesh" and "Deltares" are registered trademarks of Stichting 
!  Deltares, and remain the property of Stichting Deltares. All rights reserved.
!                                                                               
!-------------------------------------------------------------------------------

  ! return in c memory order
  select case(var_name)

    case("DFM_COMM_DFMWORLD")
       shape(1) = 0
    case("iglobal_s")
       shape(1) = ndx
    case("hwav")
       shape(1) = ndx
    case("twav")
       shape(1) = ndx
    case("Uorb")
       shape(1) = ndx
    case("infilt")
       shape(1) = ndx
    case("infiltcap")
       shape(1) = ndx
    case("shx")
       shape(1) = nshiptxy
    case("shy")
       shape(1) = nshiptxy
    case("shi")
       shape(1) = nshiptxy
    case("zsp")
       shape(1) = ndx
    case("zsp0")
       shape(1) = ndx
    case("zspc")
       shape(1) = numk
    case("zspc0")
       shape(1) = numk
    case("v0ship")
       shape(1) = ndx
    case("v1ship")
       shape(1) = ndx
    case("qinship")
       shape(1) = ndx
    case("vicushp")
       shape(1) = lnx
    case("shL")
       shape(1) = 2
    case("shB")
       shape(1) = 2
    case("shd")
       shape(1) = 2
    case("stuw")
       shape(1) = 2
    case("fstuw")
       shape(1) = 2
    case("stuwmx")
       shape(1) = 2
    case("roer")
       shape(1) = 2
    case("froer")
       shape(1) = 2
    case("roermx")
       shape(1) = 2
    case("wx")
       shape(1) = lnx
    case("wy")
       shape(1) = lnx
    case("wmag")
       shape(1) = lnx
    case("rain")
       shape(1) = ndx
    case("evap")
       shape(1) = ndx
    case("numlatsg")
       shape(1) = 0
    case("qplat")
       shape(1) = numlatsg
    case("qqlat")
       shape(1) = ndx
    case("balat")
       shape(1) = numlatsg
    case("nnlat")
       shape(1) = ndx
    case("qinext")
       shape(1) = ndkx
    case("qinextreal")
       shape(1) = ndkx
    case("vincum")
       shape(1) = ndkx
    case("rnveg")
       shape(1) = ndkx
    case("diaveg")
       shape(1) = ndkx
    case("cfuveg")
       shape(1) = lnx
    case("alfaveg")
       shape(1) = lnx
    case("stemdens")
       shape(1) = ndx
    case("stemdiam")
       shape(1) = ndx
    case("stemheight")
       shape(1) = ndx
    case("zws")
       shape(1) = ndkx
    case("kbot")
       shape(1) = ndx
    case("ktop")
       shape(1) = ndx
    case("Lbot")
       shape(1) = lnx
    case("Ltop")
       shape(1) = lnx
    case("s0")
       shape(1) = ndx
    case("s1")
       shape(1) = ndx
    case("a0")
       shape(1) = ndx
    case("a1")
       shape(1) = ndx
    case("vol0")
       shape(1) = ndx
    case("vol1")
       shape(1) = ndx
    case("hs")
       shape(1) = ndx
    case("ucx")
       shape(1) = ndkx
    case("ucy")
       shape(1) = ndkx
    case("ucz")
       shape(1) = ndkx
    case("sa0")
       shape(1) = ndkx
    case("sa1")
       shape(1) = ndkx
    case("satop")
       shape(1) = ndx
    case("sabot")
       shape(1) = ndx
    case("tem0")
       shape(1) = ndkx
    case("tem1")
       shape(1) = ndkx
    case("u1")
       shape(1) = lnkx
    case("u_to_umain")
       shape(1) = lnkx
    case("q1")
       shape(1) = lnkx
    case("au")
       shape(1) = lnkx
    case("hu")
       shape(1) = lnx
    case("frcu")
       shape(1) = lnx
    case("viusp")
       shape(1) = lnx
    case("diusp")
       shape(1) = lnx
    case("ndxi")
       shape(1) = 0
    case("ndx1db")
       shape(1) = 0
    case("kfs")
       shape(1) = ndx
    case("kfst0")
       shape(1) = ndx
    case("bare")
       shape(1) = ndx
    case("bl")
       shape(1) = ndx
    case("lnx1D")
       shape(1) = 0
    case("lnxi")
       shape(1) = 0
    case("lnx1Db")
       shape(1) = 0
    case("lnx")
       shape(1) = 0
    case("ln")
       shape(2) = 2
       shape(1) = lnkx
    case("lncn")
       shape(2) = 2
       shape(1) = lnkx
    case("iadv")
       shape(1) = lnx
    case("dx")
       shape(1) = lnx
    case("wu")
       shape(1) = lnx
    case("bob")
       shape(2) = 2
       shape(1) = lnx
    case("vort")
       shape(1) = ndx
    case("xzw")
       shape(1) = nump
    case("yzw")
       shape(1) = nump
    case("xk")
       shape(1) = numk
    case("yk")
       shape(1) = numk
    case("zk")
       shape(1) = numk
    case("kn")
       shape(2) = 3
       shape(1) = numl
    case("numk")
       shape(1) = 0
    case("zbnd1d2d1")
       shape(1) = nbnd1d2d
    case("zbnd1d2d0")
       shape(1) = nbnd1d2d
    case("zcrest1d2d")
       shape(1) = nbnd1d2d
    case("edgenumbers1d2d")
       shape(1) = nbnd1d2d
    case("kbnd1d2d")
       shape(2) = 5
       shape(1) = nbnd1d2d
    case("width_1d")
       shape(1) = nbnd1d2d
    case("qzeta_1d2d")
       shape(1) = nbnd1d2d
    case("qlat_1d2d")
       shape(1) = nbnd1d2d
    case("qtotal_1d2d")
       shape(1) = nbnd1d2d
    case("is_sumvalsnd")
       shape(2) = is_numndvals
       shape(1) = ndx
    case("is_maxvalsnd")
       shape(2) = is_numndvals
       shape(1) = ndx
    case("is_dtint")
       shape(1) = 0
    case("ndx2d")
       shape(1) = 0
    case("ndx")
       shape(1) = 0
    case("xz")
       shape(1) = ndx
    case("yz")
       shape(1) = ndx
    case("ba")
       shape(1) = ndx
  end select
