// OpenSCAD Compound Planetary System
// (c) 2019, tmackay
//
// Licensed under a Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) license, http://creativecommons.org/licenses/by-sa/4.0.
//include <MCAD/involute_gears.scad> 

// Which one would you like to see?
part = "core"; // [box:Box,lower:Lower Half,upper:Upper Half,core:Core]

// Use for command line option '-Dgen=n', overrides 'part'
// 0-7+ - generate parts individually in assembled positions. Combine with MeshLab.
// 0 box
// 1 ring gears and jaws
// 2 sun gear and knob
// 3+ planet gears
gen=undef;

/*
P1	P2	R1	R2	S1=2*P1	S2=2*P2	n1	n2	Gear Ratio
8	5	34	20	16	10	-2	0	-38.66666667
8	6	34	23	16	12	-2	1	-22.23333333
8	7	34	26	16	14	-2	2	-16.75555556
*/

// Overall scale (to avoid small numbers, internal faces or non-manifold edges)
scl = 1000;

// External dimensions of cube
cube_w_ = 76.2;
cube_w = cube_w_*scl;

// Number of planet gears in inner circle
planets = 5; //[3:1:21]

// Height of planetary layers (layer_h will be subtracted from gears>0)
gh_ = [7.2, 7.4, 7.4, 7.4, 7.4, 7.4];
gh = scl*gh_;
// Modules, planetary layers
modules = len(gh); //[2:1:3]

// Number of teeth in planet gears
pt = [5, 6, 7, 7, 6, 5];
// For additional gear ratios we can add or subtract extra teeth (in multiples of planets) from rings but the profile will be further from ideal
of = 0*gh_;
// number of teeth to twist across
nt = pt/pt[0];
// Sun gear multiplier
sgm = 2; //[1:1:5]
// For fused sun gears, we require them to be a multiple of the planet teeth
dt = pt*sgm;
// Find closest ring gear to ideal
// and add offset
rt = [for(i=[0:modules-1])round((2*dt[i]+2*pt[i])/planets+of[i])*planets-dt[i]];
// Outer diameter of core
outer_d_ = 36.0; //[30:0.2:300]
outer_d = scl*outer_d_;
// Ring wall thickness (relative pitch radius)
wall_ = 3.1; //[0:0.1:20]
wall = scl*wall_;

// Hollow - might actually increase print time but could help for SLA
Hollow = 0;				// [1:Yes , 0:No]
// Box wall thickness when hollow
hol_ = 1.22; //[0:0.1:20]
hol = scl*hol_;
// Add additional thickness to allow embossed art when hollow
dep_ = 0.5; //[0:0.1:20]
dep = scl*dep_;

// Negative - tinkercad import will fill in hollow shapes (most unhelpful). This will also save a subtraction operation ie. This will give us the shape to subtract from the art cube directly.
Negative = 1;				// [1:No, 0.5:Yes, 0:Half]

// Calculate cp based on desired ring wall thickness
cp=(outer_d/2-wall)*360/(dt+2*pt);

// what ring should be for teeth to mesh without additional scaling
rtn = dt+2*pt;
// scale ring gear (approximate profile shift)
s=[for(i=[0:modules-1])rtn[i]/rt[i]];
// scale helix angle to mesh
ha=[for(i=[0:modules-1])atan(PI*nt[i]*cp[i]/90/gh[i])];
has=[for(i=[0:modules-1])atan(PI*nt[i]*s[i]*cp[i]/90/gh[i])];

// Shaft diameter
shaft_d_ = 6; //[0:0.1:25]
shaft_d = scl*shaft_d_;
// Spring inner diameter
spring_d_ = 4.5; //[0:0.1:25]
spring_d = scl*spring_d_;
// False gate depth
fg_ = 1; //[0:0.1:5]
fg = scl*fg_;

// secondary shafts (for larger sun gears)
shafts = 6; //[0:1:12]
// Width of outer teeth
outer_w_=3; //[0:0.1:10]
outer_w=scl*outer_w_;
// Aspect ratio of teeth (depth relative to width)
teeth_a=0.75;
// Offset of wider teeth (angle)
outer_o=2; //[0:0.1:10]
// Gear depth ratio
depth_ratio=0.5; //[0:0.05:1]
// Gear clearance
tol_=0.2; //[0:0.01:0.5]
tol=scl*tol_;
// pressure angle
P=30; //[30:60]
// Layer height (for ring horizontal split)
layer_h_ = 0.2; //[0:0.01:1]
layer_h = scl*layer_h_;
// height of rim (ideally a multiple of layer_h
rim_h=3;
// Chamfer exposed gears, top - watch fingers
ChamferGearsTop = 0;				// [1:No, 0.5:Yes, 0:Half]
// Chamfer exposed gears, bottom - help with elephant's foot/tolerance
ChamferGearsBottom = 0;				// [1:No, 0.5:Yes, 0:Half]

// Curve resolution settings, minimum angle
$fa = 5/1;
// Curve resolution settings, minimum size
$fs = 1/1;
// Curve resolution settings, number of segments
$fn=96;

// Planetary gear ratio for fixed ring: 1:1+R/S
//echo(str("Gear ratio of first planetary stage: 1:", 1+ring_t1/drive_t));

// (Planet/Ring interaction: Nr*wr-Np*wp=(Nr-Np)*wc)
// one revolution of carrier (wc=1) turns planets on their axis
// wp = (Np-Nr)/Np = eg. (10-31)/10=-2.1 turns
// Secondary Planet/Ring interaction
// wr = ((Nr-Np)+Np*wp)/Nr = eg. ((34-11)-11*2.1)/34 = 1/340
// or Nr2/((Nr2-Np2)+Np2*(Np1-Nr1)/Np1)
//echo(str("Gear ratio of planet/ring stage: 1:", abs(ring_t2/((ring_t2-planet_t2)+planet_t2*(planet_t-ring_t1)/planet_t)))); // eg. 3.8181..

// Final gear ratio is product of above, eg. 1:1298.18..
//echo(str("Input/Output gear ratio: 1:",abs((1+ring_t1/drive_t)*ring_t2/((ring_t2-planet_t2)+planet_t2*(planet_t-ring_t1)/planet_t))));

// sanity check
for (i=[1:modules-1]){
    if ((dt[i]+rt[i])%planets)
        echo(str("Warning: For even spacing, planets (", i, ") must divide ", dt[i]+rt[i]));
    if (dt[i] + 2*pt[i] != rt[i])
        echo(str("Teeth fewer than ideal (ring", i, "): ", dt[i]+2*pt[i]-rt[i]));
    if(i<modules-1)echo(str("Input/Output gear ratio (ring", i, "): 1:",abs((1+rt[modules-1]/dt[modules-1])*rt[i]/((rt[i]-pt[i])+pt[i]*(pt[modules-1]-rt[modules-1])/pt[modules-1]))));
}

g=addl([for(i=[0:modules-1])(dt[i]+rt[i])%planets],modules)?99:gen;

// Calibration cube (invalid input)
if (g==99) {
    translate(scl*10*[-1,-1,0])cube(scl*20);
}

// Tolerances for geometry connections.
AT=scl/64;
ST=AT*2;
TT=AT/2;

core_h=addl(gh,modules);
core_h2 = (cube_w-core_h)/2;

r=1*scl+outer_d/2-4*tol;
h=core_h2;
d=h/4;

// overhang test
if(g==undef&&part=="test"){
    //gear2DS(dt[0],cp[0]*PI/180,P,depth_ratio,tol,gh[1]);
    
    //gear2DS(pt[0],cp[0]*PI/180,P,depth_ratio,tol,gh[1]);
    ring2DS(rt[0],s[0]*cp[0]*PI/180,P,depth_ratio,-tol,gh[1],outer_d/2);

}

// Spring
if(g==undef&&part=="spring"){
    difference(){
        translate([0,0,core_h2-cube_w/2+tol+shaft_d+0.25*shaft_d])
            cylinder(d=shaft_d-2*tol,h=cube_w/2-core_h2-tol-1.25*shaft_d-tol,$fn=6);
        translate([0,0,-7.5*scl])cylinder(d=5*scl,h=7.5*scl);
    }
    translate([0,0,-7.5*scl])cylinder(d=3*scl,h=7.5*scl-tol);
    translate([0,0,core_h2-cube_w/2+tol+shaft_d])cylinder(d2=shaft_d-2*tol,d1=0.6*shaft_d,h=shaft_d/4,$fn=6);

    // for point of reference
    /*translate([0,0,core_h2-cube_w/2-AT])cylinder(d=shaft_d-2*tol,h=0.75*shaft_d,$fn=6);
    translate([0,0,core_h2+0.75*shaft_d-cube_w/2-AT])cylinder(d1=shaft_d-2*tol,d2=0.6*shaft_d,h=shaft_d/4,$fn=6);
    mirror([0,0,1]){
        translate([0,0,core_h2-cube_w/2-AT])cylinder(d=shaft_d-2*tol,h=0.75*shaft_d,$fn=6);
        translate([0,0,core_h2+0.75*shaft_d-cube_w/2-AT])cylinder(d1=shaft_d-2*tol,d2=0.6*shaft_d,h=shaft_d/4,$fn=6);
    }*/
}

// Spiral
if(g==undef&&part=="spiral"){
    spiral();
    //spiral_();
}

module spiral(R=2*scl+tol){
    e=1/128;
    a=41;
    d=teeth_a*outer_w;
    translate([0,d/2,0]){
        mirror([0,1,1])
            linear_extrude(2.5*d)spiral2d();
        translate([-2*R,0,0]){
            rotate_extrude(angle=a+e, convexity=10, $fn=24) // some manifold issues with this join
                translate([2*R, 0]) spiral2d();
            rotate([0,0,a])translate([4*R,0,0]){
                mirror([1,0,0])
                    rotate_extrude(angle=45, convexity=10, $fn=24)
                        translate([2*R, 0]) spiral2d();
                rotate([0,0,-45])translate([-R,0,0])
                    mirror([1,0,0])rotate_extrude(angle=205, convexity=10, $fn=24)
                        translate([R, 0]) spiral2d();
            }
        }
    }
}
module spiral_(R=2*scl+tol){
    translate([R-4*R*(1-1/sqrt(2)),4*R/sqrt(2),0])
        mirror([1,0,0])rotate_extrude(angle=205, convexity=10, $fn=24)
            translate([R, 0]) spiral2d();
    
    translate([-4*R*(1-1/sqrt(2)),4*R/sqrt(2),0])
        mirror([1,0,0])mirror([0,1,0])
            translate([-2*R,0,0])
                rotate_extrude(angle=45, convexity=10, $fn=24)
                    translate([2*R, 0]) spiral2d();
    
    translate([-2*R,0,0])
        rotate_extrude(angle=45+1/128, convexity=10, $fn=24) // some manifold issues with this join
            translate([2*R, 0]) spiral2d();
}

module spiral2d(r=gh[0]/4){
    mirror([1,1,0])scale([1,0.75,1]){
        difference(){
            translate([0,-r/2,0])circle(r=r,$fn=6);
            translate([0,r/2-tol,0])circle(r=r,$fn=6);
        }
        difference(){
            translate([0,r/2,0])circle(r=r,$fn=6);
            translate([0,tol-r/2,0])circle(r=r,$fn=6);
        }
    }
}

module click2d(r=gh[0]/4){
    mirror([1,1,0])scale([1,0.75,1]){
        intersection(){
            translate([0,r/2-tol,0])circle(r=r,$fn=6);
            translate([0,tol-r/2,0])circle(r=r,$fn=6);
        }
    }
}

// Box
if(g==0||g==undef&&(part=="box"||part=="lower"||part=="upper"))difference(){
    if(Negative)cube(cube_w,center=true);
    lament();
}

module lament(){
    if(g==0||part=="box"||part=="lower")lamenthalf(turns=true)children();
    if(g==0||part=="box"||part=="upper")mirror([0,0,1])mirror([0,1,0])lamenthalf()mirror([0,0,1])mirror([0,1,0])children();
}

module lamenthalf(turns=false){
    // "clicker"
    if(!turns){
        r1=outer_d/2+2*tol;
        d=teeth_a*outer_w;
        rotate([0,0,-360/32+360/64+360/128-360/256])translate([r1+d,0,0])rotate([0,0,-30])mirror([1,0,1])mirror([1,1,0])
            translate([0,0,-d/2])linear_extrude(d+2*tol)click2d();
    }
    difference(){
        union(){
            // top ledge
            translate([0,0,1*scl-cube_w/2])
                cylinder(r1=outer_d/2+teeth_a*outer_w, r2=outer_d/2, h=(rim_h-1)*scl-layer_h+AT);
            translate([0,0,-cube_w/2])
                cylinder(r=outer_d/2+teeth_a*outer_w, h=1*scl+AT);

            translate([0,0,-cube_w/2])
                cylinder(d=outer_d,h=core_h2-tol,$fn=96);
            for (i=[0:2:15]){
                difference(){
                    intersection(){
                        cube(cube_w,center=true);
                        rotate([0,0,i*360/16])
                            translate([cube_w/2+tol,cube_w/2,0])cube(cube_w,center=true);
                        rotate([0,0,(i-1)*360/16])
                            translate([-cube_w/2-tol,cube_w/2,0])cube(cube_w,center=true);
                    }
                    translate([0,0,core_h2-tol-cube_w/2])
                        cylinder(d=outer_d+4*tol,h=cube_w-core_h2+tol+AT);
                }
            }
            // TODO: use of tol for vertical clearances - use multiple of layer_h instead
            translate([0,0,core_h2-cube_w/2-tol-AT])cylinder(d=r,h=tol+AT);
            translate([0,0,core_h2-cube_w/2-AT])cylinder(d=shaft_d-2*tol,h=gh[0]);
            translate([0,0,core_h2+gh[0]-cube_w/2-ST])cylinder(d=spring_d,h=gh[0]/2);
            
            // outer teeth
            intersection(){
                r=(shaft_d+outer_w/sqrt(2))/2-2*tol;
                r1=shaft_d/2-2*tol;
                h=gh[0]/2;
                d=teeth_a*outer_w;
                dz=d/sqrt(3);
                translate([0,0,core_h2+gh[0]/2-cube_w/2])rotate_extrude()
                    polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
                for(j = [0:1])rotate([0,0,180*j])
                    translate([r,0,core_h2+gh[0]/2-cube_w/2])scale([2,1,1])rotate([0,0,45])
                        cylinder(d=outer_w-4*tol,h=core_h+core_h2+tol+ST,$fn=4);
            }
        }

        // Dial spool track
        // TODO: parameterise dial diameter and hard coded offsets, scope global variables
        translate([0,0,-cube_w/2])rotate_extrude()
            polygon( points=[
                [r,-AT],[r,1*scl],[r-2.5*d,2*d],[r-2.5*d,h-1.5*d],[r-d,h-1*scl],[r-d,h+AT],[r-d-2*tol,h+AT],
                [r-d-2*tol,h-1*scl],[r-2.5*d-2*tol,h-1.5*d],[r-2.5*d-2*tol,2*d],[r-2*tol,1*scl],[r-2*tol,-AT]]);
        intersection(){
            r=(outer_d+outer_w/sqrt(2))/2+2*tol;
            r1=outer_d/2+2*tol;
            h=core_h+core_h2;
            d=teeth_a*outer_w;
            dz=d/sqrt(3);
            translate([0,0,gh[0]/4-cube_w/2+core_h2])
                rotate_extrude()
                    polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
            // outer teeth
            for(j = [1:8])rotate([0,0,(j-1/4)*360/8+(turns?0:(j%2?outer_o:-outer_o))])
                translate([r,0,core_h2-cube_w/2-tol-AT])scale([2,1,1])rotate([0,0,45])
                    cylinder(d=outer_w+4*tol,h=core_h+core_h2+tol+ST,$fn=4);
        }
        intersection(){
            r=(outer_d+outer_w/sqrt(2))/2+2*tol;
            r1=outer_d/2+2*tol;
            h=gh[0]/2+gh[1]+gh[2]+core_h/2+core_h2; // TODO: module dependant
            d=teeth_a*outer_w;
            dz=d/sqrt(3);
            translate([0,0,core_h2-cube_w/2])
                rotate_extrude()
                    polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
            // outer teeth
            for(j = [3*360/32:360/8:360]){
                rotate([0,0,j+outer_o])
                    translate([r,0,core_h2-cube_w/2-tol-AT])scale([2,1,1])rotate([0,0,45])
                        cylinder(d=outer_w+4*tol,h=core_h+core_h2+tol+ST,$fn=4);
                rotate([0,0,j-outer_o])
                    translate([r,0,core_h2-cube_w/2-tol-AT])scale([2,1,1])rotate([0,0,45])
                        cylinder(d=outer_w+4*tol,h=core_h+core_h2+tol+ST,$fn=4);
            }
        }
        for (i=[1:modules-2])translate([0,0,addl(gh,i)-cube_w/2+core_h2]){
            r=(outer_d+outer_w/sqrt(2))/2+2*tol;
            r1=outer_d/2+2*tol;
            h=gh[i]/2;
            d=teeth_a*outer_w;
            dz=d/sqrt(3);
            // track
            translate([0,0,(i>modules/2-1?gh[i]/2:0)+(i>0&&i<modules/2?layer_h:0)])
                rotate_extrude()
                    polygon(points=[[r1-tol,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[r1-tol,h]]);
        }
        if(turns)for(i=[0:modules/2-1])translate([0,0,addl(gh,i)-cube_w/2+core_h2+(i>0&&i<modules/2?layer_h:0)]){
            r=(outer_d+outer_w/sqrt(2))/2+2*tol;
            r1=outer_d/2+2*tol;
            h=gh[i]/2;
            d=teeth_a*outer_w;
            dz=d/sqrt(3);
            // track
            translate([0,0,core_h/2+core_h2])
                rotate_extrude()
                    polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
        }else{
            // "clicker" cutout
            r1=outer_d/2+2*tol;
            d=teeth_a*outer_w;
            rotate([0,0,-360/32+360/64+360/128-360/256]){
                translate([r1+d,0,0])rotate([0,0,-30])mirror([-1,1,0])spiral();
            }
        }
        
        if(true){
            // "clicker" track
            r=(outer_d+outer_w/sqrt(2))/2+2*tol;
            r1=outer_d/2+2*tol;
            h=gh[0]/2;
            d=teeth_a*outer_w;
            dz=d/sqrt(3);
            translate([0,0,-gh[0]/4])
                rotate_extrude()
                    polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
        }
        
        // top ledge
        translate([0,0,cube_w/2-rim_h*scl])
            cylinder(r1=outer_d/2+2*tol, r2=outer_d/2+2*tol+teeth_a*outer_w, h=(rim_h-1)*scl+AT);
        translate([0,0,cube_w/2-1*scl])
            cylinder(r=outer_d/2+2*tol+teeth_a*outer_w, h=rim_h*scl+AT);

        // temporary section (for fiddling with spool cutout)
        // translate(-cube_w*[1,0,1])cube(2*cube_w);
    }
}

// Ring gears
if(g==1||g==undef&&part=="core")translate([0,0,core_h2-cube_w/2]){
    difference(){
        // positive volume
        for (i=[0:modules-1])translate([0,0,addl(gh,i)]){
            // ring body
            translate([0,0,i>0&&(pt[i-1]-rt[i-1])/pt[i-1]!=(pt[i]-rt[i])/pt[i]?layer_h:0])intersection(){
                cylinder(r=outer_d/2,h=gh[i]-(i>0&&(pt[i-1]-rt[i-1])/pt[i-1]!=(pt[i]-rt[i])/pt[i]?layer_h:0));
                // cutout overhanging teeth at angle
                if(i>0&&rt[i-1]!=rt[i])rotate([0,0,-180/rt[i-1]*2*nt[i-1]])
                    ring2DS(rt[i-1],s[i-1]*cp[i-1]*PI/180,P,depth_ratio,-tol,gh[i],outer_d/2);
            }
            // outer teeth
            r=(outer_d+outer_w/sqrt(2))/2;
            r1=outer_d/2;
            h=gh[i]/2;
            d=teeth_a*outer_w;
            dz=d/sqrt(3);
            for(j = [1:16])
                translate([0,0,(i>modules/2-1?gh[i]/2:0)+(i>0&&i<modules/2?layer_h:0)])intersection(){
                    union(){
                        if(((i<modules/2?0:1)+j)%2){
                            rotate([0,0,360/32+j*360/16+outer_o])
                                translate([r,0,core_h2-cube_w/2-tol-AT])scale([2,1,1])rotate([0,0,45])
                                    cylinder(d=outer_w,h=core_h+core_h2+tol+ST,$fn=4);
                            rotate([0,0,360/32+j*360/16-outer_o])
                                translate([r,0,core_h2-cube_w/2-tol-AT])scale([2,1,1])rotate([0,0,45])
                                    cylinder(d=outer_w,h=core_h+core_h2+tol+ST,$fn=4);
                        } else {
                            rotate([0,0,360/32+j*360/16-(i<modules/2?(j%4?outer_o:-outer_o):0)])translate([r,0,0])scale([2,1,1])rotate([0,0,45])
                                cylinder(d=outer_w,h=gh[i]/2,$fn=4);
                        }
                    }
                    rotate_extrude()
                        polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
                }
                
            // "clicker" tooth, (for-if to avoid extra union) TODO: average middle modules, only include if ratios match
            if(i==0)translate([0,0,cube_w/2-core_h2-gh[0]/4])intersection(){
                rotate([0,0,360/32+outer_o])
                    translate([r,0,0])scale([2,1,1])rotate([0,0,45])
                        cylinder(d=outer_w,h=gh[0]/2,$fn=4);
                rotate_extrude()
                    polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
            }
                
        }
        // negative volume
        for (i=[0:modules-1])translate([0,0,addl(gh,i)]){
            planetgear(t1=rt[i],gear_h=gh[i],tol=-tol,helix_angle=has[i],cp=s[i]*cp[i],depth_ratio=depth_ratio,P=P,AT=ST);
            // chamfer bottom gear
            if(ChamferGearsBottom<1&&i==0)translate([0,0,-TT])
                linear_extrude(height=(rt[i]*s[i]*cp[i]/360)/sqrt(3),scale=0,slices=1)
                    if(ChamferGearsTop>0)
                        hull()gear2D(rt[i],s[i]*cp[i]*PI/180,P,depth_ratio,-tol);
                    else
                        circle($fn=rt[i]*2,r=rt[i]*s[i]*cp[i]/360);
            // chamfer top gear
            if(ChamferGearsTop<1&&i==modules-1)translate([0,0,gh[i]+TT])mirror([0,0,1])
                linear_extrude(height=(rt[i]*s[i]*cp[i]/360)/sqrt(3),scale=0,slices=1)
                    if(ChamferGearsTop>0)
                        hull()gear2D(rt[i],s[i]*cp[i]*PI/180,P,depth_ratio,-tol);
                    else
                        circle($fn=rt[i]*2,r=rt[i]*s[i]*cp[i]/360);
        }
    }
}

// center gears
if(g==2||g==undef&&part=="core")translate([0,0,core_h2-cube_w/2])difference(){
    for (i = [0:modules-1]){
        // the gear itself
        translate([0,0,addl(gh,i)])intersection(){
            rotate([0,0,180/dt[i]*(1-pt[i]%2)])
                planetgear(t1=dt[i],reverse=true,bore=0,cp=cp[i],helix_angle=ha[i],gear_h=gh[i],rot=180/dt[i]*(1-pt[i]%2));
            // chamfer bottom gear
            if(ChamferGearsBottom<1&&i==0)rotate(90/pt[i])translate([0,0,-TT])
                linear_extrude(height=gh[i]+AT,scale=1+gh[i]/(dt[i]*cp[i]/360)*sqrt(3),slices=1)
                    circle($fn=dt[i]*2,r=dt[i]*cp[i]/360-ChamferGearsBottom*min(cp[i]/(2*tan(P))+tol,depth_ratio*cp[i]*PI/180+tol));
            // cutout overhanging teeth at angle
            if(i>0&&dt[i-1]!=dt[i])rotate([0,0,180/dt[i-1]*(1+2*nt[i-1]-pt[i-1]%2)])
                gear2DS(dt[i-1],cp[i-1]*PI/180,P,depth_ratio,tol,gh[i]);
            
            // chamfer top gear
            if(ChamferGearsTop<1&&i==modules-1)translate([0,0,gh[i]+TT])rotate(90/dt[i])mirror([0,0,1])
                linear_extrude(height=gh[i]+ST,scale=1+gh[i]/(dt[i]*cp[i]/360)*sqrt(3),slices=1)
                    circle($fn=dt[i]*2,r=dt[i]*cp[i]/360-ChamferGearsTop*min(cp[i]/(2*tan(P))+tol,depth_ratio*cp[i]*PI/180+tol));
        }
    }
    // cylinder shaft_d
    translate([0,0,-AT])cylinder(d=shaft_d,h=addl(gh,modules)+ST,$fn=24);
    
    // vertical track
    intersection(){
        r=(shaft_d+outer_w/sqrt(2))/2;
        r1=shaft_d/2;
        h=gh[0]*2;
        d=teeth_a*outer_w;
        dz=d/sqrt(3);
        translate([0,0,addl(gh,modules-1)])rotate_extrude($fn=24)
               polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
        for(j = [0:1])rotate([0,0,180*j])
            translate([r,0,addl(gh,modules-1)])scale([2,1,1])rotate([0,0,45])
                cylinder(d=outer_w,h=core_h+core_h2+tol+ST,$fn=4);
    }
    // locking teeth
    intersection(){
        r=(shaft_d+outer_w/sqrt(2))/2;
        r1=shaft_d/2;
        h=gh[0]*2;
        d=teeth_a*outer_w;
        dz=d/sqrt(3);
        translate([0,0,gh[0]-h])rotate_extrude($fn=24)
               polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
        for(j = [0:1])rotate([0,0,180*j])
            translate([r,0,gh[0]-h])scale([2,1,1])rotate([0,0,45])
                cylinder(d=outer_w,h=core_h+core_h2+tol+ST,$fn=4);
    }

    // false gates - we could make it a lot harder by setting h=gh[0]/2
    intersection(){
        r=(shaft_d+outer_w/sqrt(2))/2;
        r1=shaft_d/2;
        h=gh[0]/2+fg;
        d=teeth_a*outer_w;
        dz=d/sqrt(3);
        translate([0,0,addl(gh,modules-1)])rotate_extrude($fn=24)
               polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
        for(i = [-1:2:1], j = [0:1])rotate([0,0,90+180*j+i*30])
            translate([r,0,addl(gh,modules-1)])scale([2,1,1])rotate([0,0,45])
                cylinder(d=outer_w,h=core_h+core_h2+tol+ST,$fn=4);
    }
    intersection(){
        r=(shaft_d+outer_w/sqrt(2))/2;
        r1=shaft_d/2;
        h=gh[0]/2+fg;
        d=teeth_a*outer_w;
        dz=d/sqrt(3);
        translate([0,0,gh[0]-h])rotate_extrude($fn=24)
               polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
        for(i = [-1:2:1], j = [0:1])rotate([0,0,90+180*j+i*30])
            translate([r,0,gh[0]-h])scale([2,1,1])rotate([0,0,45])
                cylinder(d=outer_w,h=core_h+core_h2+tol+ST,$fn=4);
    }
    
    // track
    r=(shaft_d+outer_w/sqrt(2))/2;
    r1=shaft_d/2;
    h=gh[0]/2;
    d=teeth_a*outer_w;
    dz=d/sqrt(3);
    difference(){
        translate([0,0,addl(gh,modules-1)])
            rotate_extrude($fn=24)
                polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
            // end stops
            for(j = [0:1])rotate([0,0,90+180*j])
                translate([r,0,addl(gh,modules-1)])scale([2,1,1])rotate([0,0,45])
                    cylinder(d=outer_w*2,h=core_h+core_h2+tol+ST,$fn=4);
    }
    //translate([0,0,addl(gh,modules-1)])cylinder(r=r1+AT,h=h,$fn=24); // non-manifold tweak
    difference(){
        translate([0,0,gh[0]/2])
            rotate_extrude($fn=24)
                polygon(points=[[0,0],[r1,0],[r1+d,dz],[r1+d,h-dz],[r1,h],[0,h]]);
            // end stops
            for(j = [0:1])rotate([0,0,90+180*j])
                translate([r,0,gh[0]/2])scale([2,1,1])rotate([0,0,45])
                    cylinder(d=outer_w*2,h=core_h+core_h2+tol+ST,$fn=4);
    }
    //translate([0,0,gh[0]/2])cylinder(r=r1+AT,h=h,$fn=24); // non-manifold tweak
    //translate([0,0,gh[0]/2+h])cylinder(r=r1+tol,h=addl(gh,modules-1)-gh[0]/2-h,$fn=24); // non-manifold tweak
}

// planets
if(g>2||g==undef&&part=="core")translate([0,0,core_h2-cube_w/2]){
    planets(t1=pt[0], t2=dt[0],offset=(dt[0]+pt[0])*cp[0]/360,n=planets,t=rt[0]+dt[0])difference(){
        for (i = [0:modules-1]){
            translate([0,0,addl(gh,i)]){
                intersection(){
                    // the gear itself
                    planetgear(t1 = pt[i], bore=0,cp=cp[i],helix_angle=ha[i],gear_h=gh[i]);
                    // chamfer bottom gear
                    if(ChamferGearsBottom<1&&i==0)rotate(90/pt[i])translate([0,0,-TT])
                        linear_extrude(height=gh[i]+AT,scale=1+gh[i]/(pt[i]*cp[i]/360)*sqrt(3),slices=1)
                            circle($fn=pt[i]*2,r=pt[i]*cp[i]/360-ChamferGearsBottom*min(cp[i]/(2*tan(P))+tol,depth_ratio*cp[i]*PI/180+tol));                
                    // cutout overhanging teeth at angle
                    if(i>0&&pt[i-1]!=pt[i])rotate([0,0,180/pt[i-1]*(-2*nt[i-1])])
                        gear2DS(pt[i-1],cp[i-1]*PI/180,P,depth_ratio,tol,gh[i]);
                    // chamfer top gear
                    if(ChamferGearsTop<1&&i==modules-1)translate([0,0,gh[i]+TT])rotate(90/pt[i])mirror([0,0,1])
                        linear_extrude(height=gh[i]+ST,scale=1+gh[i]/(pt[i]*cp[i]/360)*sqrt(3),slices=1)
                            circle($fn=pt[i]*2,r=pt[i]*cp[i]/360-ChamferGearsTop*min(cp[i]/(2*tan(P))+tol,depth_ratio*cp[i]*PI/180+tol));
                }
            }
        }
        if(pt[0]*cp[0]/360-ChamferGearsTop*min(cp[0]/(2*tan(P))+tol) > shaft_d)
            translate([0,0,-TT])cylinder(d=shaft_d,h=addl(gh,modules)+AT);
    }
}

// reversible herringbone gear with bore hole
module planetgear(t1=13,reverse=false,bore=0,rot=0)
{
    difference()
    {
        translate([0,0,gear_h/2])
        if (reverse) {
            mirror([0,1,0])
                herringbone(t1,PI*cp/180,P,depth_ratio,tol,helix_angle,gear_h,AT=AT);
        } else {
            herringbone(t1,PI*cp/180,P,depth_ratio,tol,helix_angle,gear_h,AT=AT);
        }
        
        translate([0,0,-TT]){
            rotate([0,0,-rot])
                cylinder(d=bore, h=2*gear_h+AT);
            // Extra speed holes, for strength
            if(shafts>0 && bore>0 && bore/4+(t1-2*tan(P))*cp/720>bore)
                for(i = [0:360/shafts:360-360/shafts])rotate([0,0,i-rot])
                    translate([bore/4+(t1-2*tan(P))*cp/720,0,-AT])
                        cylinder(d=bore,h=2*gear_h+AT);
        }
    }
}

// Space out planet gears approximately equally
module planets()
{
    for(i = [0:n-1])if(g==undef||i==g-3)
    rotate([0,0,round(i*t/n)*360/t])
        translate([offset,0,0]) rotate([0,0,round(i*t/n)*360/t*t2/t1])
            children();
}

// Rotational and mirror symmetry
module seg(z=10){
    for(i=[0:360/z:359.9])rotate([0,0,i]){
        children();
        mirror([0,1,0])children();
    }
}

// half-tooth overhang volume
module overhang(number_of_teeth,height){
    //translate([0,0,-AT])linear_extrude(2*AT)children(); // overlap
    intersection(){
        minkowski(){
            linear_extrude(AT)children();
            intersection(){
                cylinder(r1=0,r2=height*sqrt(3),h=height,$fn=6); // 60 degree overhang
                translate([-height,AT-2*height,0])cube(2*height); // segments overlap
            }
        }
        if(number_of_teeth>1)
            rotate([0,0,-180/number_of_teeth])translate([-2*height,-AT,0])cube(10*height); // mirrored overlap
    }
}

// Herringbone gear code, taken from:
// Planetary gear bearing (customizable)
// https://www.thingiverse.com/thing:138222
// Captive Planetary Gear Set: parametric. by terrym is licensed under the Creative Commons - Attribution - Share Alike license.
module herringbone(
	number_of_teeth=15,
	circular_pitch=10,
	pressure_angle=28,
	depth_ratio=1,
	clearance=0,
	helix_angle=0,
	gear_thickness=5){
union(){
    gear(number_of_teeth,
		circular_pitch,
		pressure_angle,
		depth_ratio,
		clearance,
		helix_angle,
		gear_thickness/2);
	mirror([0,0,1])
		gear(number_of_teeth,
			circular_pitch,
			pressure_angle,
			depth_ratio,
			clearance,
			helix_angle,
			gear_thickness/2);
}}

module gear (
	number_of_teeth=15,
	circular_pitch=10,
	pressure_angle=28,
	depth_ratio=1,
	clearance=0,
	helix_angle=0,
	gear_thickness=5,
	flat=false){
pitch_radius = number_of_teeth*circular_pitch/(2*PI);
twist=tan(helix_angle)*gear_thickness/pitch_radius*180/PI;

flat_extrude(h=gear_thickness,twist=twist,flat=flat)
	gear2D (
		number_of_teeth,
		circular_pitch,
		pressure_angle,
		depth_ratio,
		clearance);
}

module flat_extrude(h,twist,flat){
	if(flat==false)
		linear_extrude(height=h,twist=twist,slices=6)children(0);
	else
		children(0);
}

module gear2D (
	number_of_teeth,
	circular_pitch,
	pressure_angle,
	depth_ratio,
	clearance){
pitch_radius = number_of_teeth*circular_pitch/(2*PI);
base_radius = pitch_radius*cos(pressure_angle);
depth=circular_pitch/(2*tan(pressure_angle));
outer_radius = clearance<0 ? pitch_radius+depth/2-clearance : pitch_radius+depth/2;
root_radius1 = pitch_radius-depth/2-clearance/2;
root_radius = (clearance<0 && root_radius1<base_radius) ? base_radius : root_radius1;
backlash_angle = clearance/(pitch_radius*cos(pressure_angle)) * 180 / PI;
half_thick_angle = 90/number_of_teeth - backlash_angle/2;
pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
min_radius = max (base_radius,root_radius);

intersection(){
	rotate(90/number_of_teeth)
		circle($fn=number_of_teeth*3,r=pitch_radius+depth_ratio*circular_pitch/2-clearance/2);
	union(){
		rotate(90/number_of_teeth)
			circle($fn=number_of_teeth*2,r=max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
		for (i = [1:number_of_teeth])rotate(i*360/number_of_teeth){
			halftooth (
				pitch_angle,
				base_radius,
				min_radius,
				outer_radius,
				half_thick_angle);		
			mirror([0,1])halftooth (
				pitch_angle,
				base_radius,
				min_radius,
				outer_radius,
				half_thick_angle);
		}
	}
}}

// volume supported above gear for removing overhang
module gear2DS (
	number_of_teeth,
	circular_pitch,
	pressure_angle,
	depth_ratio,
	clearance,
    height){
pitch_radius = number_of_teeth*circular_pitch/(2*PI);
base_radius = pitch_radius*cos(pressure_angle);
depth=circular_pitch/(2*tan(pressure_angle));
outer_radius = clearance<0 ? pitch_radius+depth/2-clearance : pitch_radius+depth/2;
root_radius1 = pitch_radius-depth/2-clearance/2;
root_radius = (clearance<0 && root_radius1<base_radius) ? base_radius : root_radius1;
backlash_angle = clearance/(pitch_radius*cos(pressure_angle)) * 180 / PI;
half_thick_angle = 90/number_of_teeth - backlash_angle/2;
pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
min_radius = max (base_radius,root_radius);

seg(number_of_teeth)overhang(number_of_teeth,height)intersection(){
	rotate(90/number_of_teeth)
		circle($fn=number_of_teeth*3,r=pitch_radius+depth_ratio*circular_pitch/2-clearance/2);
	union(){
        intersection(){
            rotate(90/number_of_teeth)
                circle($fn=number_of_teeth*2,r=max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
            mirror([0,1,0])square(max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
            rotate(-180/number_of_teeth)
                square(max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
        }
        halftooth (
			pitch_angle,
			base_radius,
			min_radius,
			outer_radius,
			half_thick_angle);		
		}
	}
}

// volume supported above ring gear for removing overhang
module ring2DS (number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance,height,radius){
    pitch_radius = number_of_teeth*circular_pitch/(2*PI);
    base_radius = pitch_radius*cos(pressure_angle);
    depth=circular_pitch/(2*tan(pressure_angle));
    outer_radius = clearance<0 ? pitch_radius+depth/2-clearance : pitch_radius+depth/2;
    root_radius1 = pitch_radius-depth/2-clearance/2;
    root_radius = (clearance<0 && root_radius1<base_radius) ? base_radius : root_radius1;
    backlash_angle = clearance/(pitch_radius*cos(pressure_angle)) * 180 / PI;
    half_thick_angle = 90/number_of_teeth - backlash_angle/2;
    pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
    pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
    min_radius = max (base_radius,root_radius);

    seg(number_of_teeth)overhang(number_of_teeth,height)difference(){
        intersection(){
            circle(r=radius);
            mirror([0,1,0])square(radius);
            rotate(-180/number_of_teeth)square(radius);
        }
        intersection(){
            rotate(90/number_of_teeth)
                circle($fn=number_of_teeth*3,r=pitch_radius+depth_ratio*circular_pitch/2-clearance/2);
            union(){
                intersection(){
                    rotate(90/number_of_teeth)
                        circle($fn=number_of_teeth*2,r=max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
                    mirror([0,1,0])square(max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
                    rotate(-180/number_of_teeth)
                        square(max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
                }
                halftooth (pitch_angle,base_radius,min_radius,outer_radius,half_thick_angle);		
            }
        }
    }
}

module halftooth (
	pitch_angle,
	base_radius,
	min_radius,
	outer_radius,
	half_thick_angle){
index=[0,1,2,3,4,5];
start_angle = max(involute_intersect_angle (base_radius, min_radius)-5,0);
stop_angle = involute_intersect_angle (base_radius, outer_radius);
angle=index*(stop_angle-start_angle)/index[len(index)-1];
p=[[0,0], // The more of these the smoother the involute shape of the teeth.
	involute(base_radius,angle[0]+start_angle),
	involute(base_radius,angle[1]+start_angle),
	involute(base_radius,angle[2]+start_angle),
	involute(base_radius,angle[3]+start_angle),
	involute(base_radius,angle[4]+start_angle),
	involute(base_radius,angle[5]+start_angle)];

difference(){
	rotate(-pitch_angle-half_thick_angle)polygon(points=p);
	square(2*outer_radius);
}}

// Mathematical Functions
//===============

// Finds the angle of the involute about the base radius at the given distance (radius) from it's center.
//source: http://www.mathhelpforum.com/math-help/geometry/136011-circle-involute-solving-y-any-given-x.html

function involute_intersect_angle (base_radius, radius) = sqrt (pow (radius/base_radius, 2) - 1) * 180 / PI;

// Calculate the involute position for a given base radius and involute angle.

function involute (base_radius, involute_angle) =
[
	base_radius*(cos (involute_angle) + involute_angle*PI/180*sin (involute_angle)),
	base_radius*(sin (involute_angle) - involute_angle*PI/180*cos (involute_angle))
];

// Recursively sums all elements of a list up to n'th element, counting from 1
function addl(list,n=0) = n>0?(n<=len(list)?list[n-1]+addl(list,n-1):list[n-1]):0;
