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

  select case(var_index)
  case(0)
     var_name = "DFM_COMM_DFMWORLD"
  case(1)
     var_name = "iglobal_s"
  case(2)
     var_name = "hwav"
  case(3)
     var_name = "twav"
  case(4)
     var_name = "Uorb"
  case(5)
     var_name = "infilt"
  case(6)
     var_name = "infiltcap"
  case(7)
     var_name = "shx"
  case(8)
     var_name = "shy"
  case(9)
     var_name = "shi"
  case(10)
     var_name = "zsp"
  case(11)
     var_name = "zsp0"
  case(12)
     var_name = "zspc"
  case(13)
     var_name = "zspc0"
  case(14)
     var_name = "v0ship"
  case(15)
     var_name = "v1ship"
  case(16)
     var_name = "qinship"
  case(17)
     var_name = "vicushp"
  case(18)
     var_name = "shL"
  case(19)
     var_name = "shB"
  case(20)
     var_name = "shd"
  case(21)
     var_name = "stuw"
  case(22)
     var_name = "fstuw"
  case(23)
     var_name = "stuwmx"
  case(24)
     var_name = "roer"
  case(25)
     var_name = "froer"
  case(26)
     var_name = "roermx"
  case(27)
     var_name = "wx"
  case(28)
     var_name = "wy"
  case(29)
     var_name = "wmag"
  case(30)
     var_name = "rain"
  case(31)
     var_name = "evap"
  case(32)
     var_name = "numlatsg"
  case(33)
     var_name = "qplat"
  case(34)
     var_name = "qqlat"
  case(35)
     var_name = "balat"
  case(36)
     var_name = "nnlat"
  case(37)
     var_name = "qinext"
  case(38)
     var_name = "qinextreal"
  case(39)
     var_name = "vincum"
  case(40)
     var_name = "rnveg"
  case(41)
     var_name = "diaveg"
  case(42)
     var_name = "cfuveg"
  case(43)
     var_name = "alfaveg"
  case(44)
     var_name = "stemdens"
  case(45)
     var_name = "stemdiam"
  case(46)
     var_name = "stemheight"
  case(47)
     var_name = "zws"
  case(48)
     var_name = "kbot"
  case(49)
     var_name = "ktop"
  case(50)
     var_name = "Lbot"
  case(51)
     var_name = "Ltop"
  case(52)
     var_name = "s0"
  case(53)
     var_name = "s1"
  case(54)
     var_name = "a0"
  case(55)
     var_name = "a1"
  case(56)
     var_name = "vol0"
  case(57)
     var_name = "vol1"
  case(58)
     var_name = "hs"
  case(59)
     var_name = "ucx"
  case(60)
     var_name = "ucy"
  case(61)
     var_name = "ucz"
  case(62)
     var_name = "sa0"
  case(63)
     var_name = "sa1"
  case(64)
     var_name = "satop"
  case(65)
     var_name = "sabot"
  case(66)
     var_name = "tem0"
  case(67)
     var_name = "tem1"
  case(68)
     var_name = "u1"
  case(69)
     var_name = "u_to_umain"
  case(70)
     var_name = "q1"
  case(71)
     var_name = "au"
  case(72)
     var_name = "hu"
  case(73)
     var_name = "frcu"
  case(74)
     var_name = "viusp"
  case(75)
     var_name = "diusp"
  case(76)
     var_name = "ndxi"
  case(77)
     var_name = "ndx1db"
  case(78)
     var_name = "kfs"
  case(79)
     var_name = "kfst0"
  case(80)
     var_name = "bare"
  case(81)
     var_name = "bl"
  case(82)
     var_name = "lnx1D"
  case(83)
     var_name = "lnxi"
  case(84)
     var_name = "lnx1Db"
  case(85)
     var_name = "lnx"
  case(86)
     var_name = "ln"
  case(87)
     var_name = "lncn"
  case(88)
     var_name = "iadv"
  case(89)
     var_name = "dx"
  case(90)
     var_name = "wu"
  case(91)
     var_name = "bob"
  case(92)
     var_name = "vort"
  case(93)
     var_name = "xzw"
  case(94)
     var_name = "yzw"
  case(95)
     var_name = "xk"
  case(96)
     var_name = "yk"
  case(97)
     var_name = "zk"
  case(98)
     var_name = "kn"
  case(99)
     var_name = "numk"
  case(100)
     var_name = "zbnd1d2d1"
  case(101)
     var_name = "zbnd1d2d0"
  case(102)
     var_name = "zcrest1d2d"
  case(103)
     var_name = "edgenumbers1d2d"
  case(104)
     var_name = "kbnd1d2d"
  case(105)
     var_name = "width_1d"
  case(106)
     var_name = "qzeta_1d2d"
  case(107)
     var_name = "qlat_1d2d"
  case(108)
     var_name = "qtotal_1d2d"
  case(109)
     var_name = "is_sumvalsnd"
  case(110)
     var_name = "is_maxvalsnd"
  case(111)
     var_name = "is_dtint"
  case(112)
     var_name = "ndx2d"
  case(113)
     var_name = "ndx"
  case(114)
     var_name = "xz"
  case(115)
     var_name = "yz"
  case(116)
     var_name = "ba"
  end select

