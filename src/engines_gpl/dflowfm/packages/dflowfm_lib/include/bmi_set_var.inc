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

  select case(var_name)
  case("DFM_COMM_DFMWORLD")
     call c_f_pointer(xptr, x_0d_int_ptr)
     DFM_COMM_DFMWORLD = x_0d_int_ptr
  case("iglobal_s")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(iglobal_s))
     iglobal_s(:) = x_1d_int_ptr
  case("hwav")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(hwav))
     hwav(:) = x_1d_double_ptr
  case("twav")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(twav))
     twav(:) = x_1d_double_ptr
  case("Uorb")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(Uorb))
     Uorb(:) = x_1d_double_ptr
  case("infilt")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(infilt))
     infilt(:) = x_1d_double_ptr
  case("infiltcap")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(infiltcap))
     infiltcap(:) = x_1d_double_ptr
  case("shx")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(shx))
     shx(:) = x_1d_double_ptr
  case("shy")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(shy))
     shy(:) = x_1d_double_ptr
  case("shi")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(shi))
     shi(:) = x_1d_double_ptr
  case("zsp")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zsp))
     zsp(:) = x_1d_double_ptr
  case("zsp0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zsp0))
     zsp0(:) = x_1d_double_ptr
  case("zspc")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zspc))
     zspc(:) = x_1d_double_ptr
  case("zspc0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zspc0))
     zspc0(:) = x_1d_double_ptr
  case("v0ship")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(v0ship))
     v0ship(:) = x_1d_double_ptr
  case("v1ship")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(v1ship))
     v1ship(:) = x_1d_double_ptr
  case("qinship")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qinship))
     qinship(:) = x_1d_double_ptr
  case("vicushp")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(vicushp))
     vicushp(:) = x_1d_double_ptr
  case("shL")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(shL))
     shL(:) = x_1d_double_ptr
  case("shB")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(shB))
     shB(:) = x_1d_double_ptr
  case("shd")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(shd))
     shd(:) = x_1d_double_ptr
  case("stuw")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(stuw))
     stuw(:) = x_1d_double_ptr
  case("fstuw")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(fstuw))
     fstuw(:) = x_1d_double_ptr
  case("stuwmx")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(stuwmx))
     stuwmx(:) = x_1d_double_ptr
  case("roer")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(roer))
     roer(:) = x_1d_double_ptr
  case("froer")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(froer))
     froer(:) = x_1d_double_ptr
  case("roermx")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(roermx))
     roermx(:) = x_1d_double_ptr
  case("wx")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(wx))
     wx(:) = x_1d_double_ptr
  case("wy")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(wy))
     wy(:) = x_1d_double_ptr
  case("wmag")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(wmag))
     wmag(:) = x_1d_double_ptr
  case("rain")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(rain))
     rain(:) = x_1d_double_ptr
  case("evap")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(evap))
     evap(:) = x_1d_double_ptr
  case("numlatsg")
     call c_f_pointer(xptr, x_0d_int_ptr)
     numlatsg = x_0d_int_ptr
  case("qplat")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qplat))
     qplat(:) = x_1d_double_ptr
  case("qqlat")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qqlat))
     qqlat(:) = x_1d_double_ptr
  case("balat")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(balat))
     balat(:) = x_1d_double_ptr
  case("nnlat")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(nnlat))
     nnlat(:) = x_1d_int_ptr
  case("qinext")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qinext))
     qinext(:) = x_1d_double_ptr
  case("qinextreal")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qinextreal))
     qinextreal(:) = x_1d_double_ptr
  case("vincum")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(vincum))
     vincum(:) = x_1d_double_ptr
  case("rnveg")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(rnveg))
     rnveg(:) = x_1d_double_ptr
  case("diaveg")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(diaveg))
     diaveg(:) = x_1d_double_ptr
  case("cfuveg")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(cfuveg))
     cfuveg(:) = x_1d_double_ptr
  case("alfaveg")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(alfaveg))
     alfaveg(:) = x_1d_double_ptr
  case("stemdens")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(stemdens))
     stemdens(:) = x_1d_double_ptr
  case("stemdiam")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(stemdiam))
     stemdiam(:) = x_1d_double_ptr
  case("stemheight")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(stemheight))
     stemheight(:) = x_1d_double_ptr
  case("zws")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zws))
     zws(:) = x_1d_double_ptr
  case("kbot")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(kbot))
     kbot(:) = x_1d_int_ptr
  case("ktop")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(ktop))
     ktop(:) = x_1d_int_ptr
  case("Lbot")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(Lbot))
     Lbot(:) = x_1d_int_ptr
  case("Ltop")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(Ltop))
     Ltop(:) = x_1d_int_ptr
  case("s0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(s0))
     s0(:) = x_1d_double_ptr
  case("s1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(s1))
     s1(:) = x_1d_double_ptr
  case("a0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(a0))
     a0(:) = x_1d_double_ptr
  case("a1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(a1))
     a1(:) = x_1d_double_ptr
  case("vol0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(vol0))
     vol0(:) = x_1d_double_ptr
  case("vol1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(vol1))
     vol1(:) = x_1d_double_ptr
  case("hs")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(hs))
     hs(:) = x_1d_double_ptr
  case("ucx")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(ucx))
     ucx(:) = x_1d_double_ptr
  case("ucy")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(ucy))
     ucy(:) = x_1d_double_ptr
  case("ucz")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(ucz))
     ucz(:) = x_1d_double_ptr
  case("sa0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(sa0))
     sa0(:) = x_1d_double_ptr
  case("sa1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(sa1))
     sa1(:) = x_1d_double_ptr
  case("satop")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(satop))
     satop(:) = x_1d_double_ptr
  case("sabot")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(sabot))
     sabot(:) = x_1d_double_ptr
  case("tem0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(tem0))
     tem0(:) = x_1d_double_ptr
  case("tem1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(tem1))
     tem1(:) = x_1d_double_ptr
  case("u1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(u1))
     u1(:) = x_1d_double_ptr
  case("u_to_umain")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(u_to_umain))
     u_to_umain(:) = x_1d_double_ptr
  case("q1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(q1))
     q1(:) = x_1d_double_ptr
  case("au")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(au))
     au(:) = x_1d_double_ptr
  case("hu")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(hu))
     hu(:) = x_1d_double_ptr
  case("frcu")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(frcu))
     frcu(:) = x_1d_double_ptr
  case("viusp")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(viusp))
     viusp(:) = x_1d_double_ptr
  case("diusp")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(diusp))
     diusp(:) = x_1d_double_ptr
  case("ndxi")
     call c_f_pointer(xptr, x_0d_int_ptr)
     ndxi = x_0d_int_ptr
  case("ndx1db")
     call c_f_pointer(xptr, x_0d_int_ptr)
     ndx1db = x_0d_int_ptr
  case("kfs")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(kfs))
     kfs(:) = x_1d_int_ptr
  case("kfst0")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(kfst0))
     kfst0(:) = x_1d_int_ptr
  case("bare")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(bare))
     bare(:) = x_1d_double_ptr
  case("bl")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(bl))
     bl(:) = x_1d_double_ptr
  case("lnx1D")
     call c_f_pointer(xptr, x_0d_int_ptr)
     lnx1D = x_0d_int_ptr
  case("lnxi")
     call c_f_pointer(xptr, x_0d_int_ptr)
     lnxi = x_0d_int_ptr
  case("lnx1Db")
     call c_f_pointer(xptr, x_0d_int_ptr)
     lnx1Db = x_0d_int_ptr
  case("lnx")
     call c_f_pointer(xptr, x_0d_int_ptr)
     lnx = x_0d_int_ptr
  case("ln")
     call c_f_pointer(xptr, x_2d_int_ptr, shape(ln))
     ln(:,:) = x_2d_int_ptr
  case("lncn")
     call c_f_pointer(xptr, x_2d_int_ptr, shape(lncn))
     lncn(:,:) = x_2d_int_ptr
  case("iadv")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(iadv))
     iadv(:) = x_1d_int_ptr
  case("dx")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(dx))
     dx(:) = x_1d_double_ptr
  case("wu")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(wu))
     wu(:) = x_1d_double_ptr
  case("bob")
     call c_f_pointer(xptr, x_2d_double_ptr, shape(bob))
     bob(:,:) = x_2d_double_ptr
  case("vort")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(vort))
     vort(:) = x_1d_double_ptr
  case("xzw")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(xzw))
     xzw(:) = x_1d_double_ptr
  case("yzw")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(yzw))
     yzw(:) = x_1d_double_ptr
  case("xk")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(xk))
     xk(:) = x_1d_double_ptr
  case("yk")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(yk))
     yk(:) = x_1d_double_ptr
  case("zk")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zk))
     zk(:) = x_1d_double_ptr
  case("kn")
     call c_f_pointer(xptr, x_2d_int_ptr, shape(kn))
     kn(:,:) = x_2d_int_ptr
  case("numk")
     call c_f_pointer(xptr, x_0d_int_ptr)
     numk = x_0d_int_ptr
  case("zbnd1d2d1")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zbnd1d2d1))
     zbnd1d2d1(:) = x_1d_double_ptr
  case("zbnd1d2d0")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zbnd1d2d0))
     zbnd1d2d0(:) = x_1d_double_ptr
  case("zcrest1d2d")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(zcrest1d2d))
     zcrest1d2d(:) = x_1d_double_ptr
  case("edgenumbers1d2d")
     call c_f_pointer(xptr, x_1d_int_ptr, shape(edgenumbers1d2d))
     edgenumbers1d2d(:) = x_1d_int_ptr
  case("kbnd1d2d")
     call c_f_pointer(xptr, x_2d_int_ptr, shape(kbnd1d2d))
     kbnd1d2d(:,:) = x_2d_int_ptr
  case("width_1d")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(width_1d))
     width_1d(:) = x_1d_double_ptr
  case("qzeta_1d2d")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qzeta_1d2d))
     qzeta_1d2d(:) = x_1d_double_ptr
  case("qlat_1d2d")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qlat_1d2d))
     qlat_1d2d(:) = x_1d_double_ptr
  case("qtotal_1d2d")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(qtotal_1d2d))
     qtotal_1d2d(:) = x_1d_double_ptr
  case("is_sumvalsnd")
     call c_f_pointer(xptr, x_2d_double_ptr, shape(is_sumvalsnd))
     is_sumvalsnd(:,:) = x_2d_double_ptr
  case("is_maxvalsnd")
     call c_f_pointer(xptr, x_2d_double_ptr, shape(is_maxvalsnd))
     is_maxvalsnd(:,:) = x_2d_double_ptr
  case("is_dtint")
     call c_f_pointer(xptr, x_0d_double_ptr)
     is_dtint = x_0d_double_ptr
  case("ndx2d")
     call c_f_pointer(xptr, x_0d_int_ptr)
     ndx2d = x_0d_int_ptr
  case("ndx")
     call c_f_pointer(xptr, x_0d_int_ptr)
     ndx = x_0d_int_ptr
  case("xz")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(xz))
     xz(:) = x_1d_double_ptr
  case("yz")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(yz))
     yz(:) = x_1d_double_ptr
  case("ba")
     call c_f_pointer(xptr, x_1d_double_ptr, shape(ba))
     ba(:) = x_1d_double_ptr
  end select
